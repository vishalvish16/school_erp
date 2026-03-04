// =============================================================================
// FILE: lib/core/theme/app_text_styles.dart
// PURPOSE: Typography tokens — Inter font, full semantic scale
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Returns the base Inter TextTheme used in both light and dark MaterialTheme.
TextTheme buildInterTextTheme(ColorScheme scheme) {
  final baseTheme = GoogleFonts.interTextTheme();
  return baseTheme.copyWith(
    // ── Display ──────────────────────────────────────────────────────────────
    displayLarge: baseTheme.displayLarge?.copyWith(
      fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -0.25,
      color: scheme.onSurface,
    ),
    displayMedium: baseTheme.displayMedium?.copyWith(
      fontSize: 45, fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    displaySmall: baseTheme.displaySmall?.copyWith(
      fontSize: 36, fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),

    // ── Headline (H1-H3) ─────────────────────────────────────────────────────
    headlineLarge: baseTheme.headlineLarge?.copyWith(
      fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
      color: scheme.onSurface,
    ),
    headlineMedium: baseTheme.headlineMedium?.copyWith(
      fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25,
      color: scheme.onSurface,
    ),
    headlineSmall: baseTheme.headlineSmall?.copyWith(
      fontSize: 24, fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),

    // ── Title (H4-H6) ────────────────────────────────────────────────────────
    titleLarge: baseTheme.titleLarge?.copyWith(
      fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.15,
      color: scheme.onSurface,
    ),
    titleMedium: baseTheme.titleMedium?.copyWith(
      fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    titleSmall: baseTheme.titleSmall?.copyWith(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: scheme.onSurface,
    ),

    // ── Body ─────────────────────────────────────────────────────────────────
    bodyLarge: baseTheme.bodyLarge?.copyWith(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15,
      color: scheme.onSurface,
    ),
    bodyMedium: baseTheme.bodyMedium?.copyWith(
      fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
      color: scheme.onSurface,
    ),
    bodySmall: baseTheme.bodySmall?.copyWith(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
      color: scheme.onSurfaceVariant,
    ),

    // ── Label / Caption ───────────────────────────────────────────────────────
    labelLarge: baseTheme.labelLarge?.copyWith(
      fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1,
      color: scheme.onSurface,
    ),
    labelMedium: baseTheme.labelMedium?.copyWith(
      fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: scheme.onSurface,
    ),
    labelSmall: baseTheme.labelSmall?.copyWith(
      fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: scheme.onSurfaceVariant,
    ),
  );
}

/// Static text style helpers — use when you need a one-off style
/// that doesn't depend on a BuildContext.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // ── Heading scale ──────────────────────────────────────────────────────────
  /// H1 — 32px / Bold — page titles
  static TextStyle h1({Color? color}) => _inter(
        size: 32, weight: FontWeight.w700, letterSpacing: -0.5,
        height: 1.2, color: color,
      );

  /// H2 — 28px / SemiBold — section headers
  static TextStyle h2({Color? color}) => _inter(
        size: 28, weight: FontWeight.w600, letterSpacing: -0.25,
        height: 1.25, color: color,
      );

  /// H3 — 24px / SemiBold — card headers
  static TextStyle h3({Color? color}) => _inter(
        size: 24, weight: FontWeight.w600, height: 1.3, color: color,
      );

  /// H4 — 20px / SemiBold
  static TextStyle h4({Color? color}) => _inter(
        size: 20, weight: FontWeight.w600, letterSpacing: 0.15,
        height: 1.35, color: color,
      );

  /// H5 — 16px / SemiBold
  static TextStyle h5({Color? color}) => _inter(
        size: 16, weight: FontWeight.w600, letterSpacing: 0.1,
        height: 1.4, color: color,
      );

  /// H6 — 14px / SemiBold
  static TextStyle h6({Color? color}) => _inter(
        size: 14, weight: FontWeight.w600, letterSpacing: 0.1,
        height: 1.4, color: color,
      );

  // ── Body scale ──────────────────────────────────────────────────────────────
  /// Body Large — 16px / Regular
  static TextStyle bodyLg({Color? color}) => _inter(
        size: 16, weight: FontWeight.w400, letterSpacing: 0.15,
        height: 1.5, color: color,
      );

  /// Body — 14px / Regular (default)
  static TextStyle body({Color? color}) => _inter(
        size: 14, weight: FontWeight.w400, letterSpacing: 0.25,
        height: 1.5, color: color,
      );

  /// Body Medium weight — 14px / Medium
  static TextStyle bodyMd({Color? color}) => _inter(
        size: 14, weight: FontWeight.w500, letterSpacing: 0.1,
        height: 1.5, color: color,
      );

  /// Body Small — 12px / Regular
  static TextStyle bodySm({Color? color}) => _inter(
        size: 12, weight: FontWeight.w400, letterSpacing: 0.4,
        height: 1.5, color: color,
      );

  // ── Label / UI ──────────────────────────────────────────────────────────────
  /// Button label — 14px / Medium
  static TextStyle buttonLabel({Color? color}) => _inter(
        size: 14, weight: FontWeight.w500, letterSpacing: 0.1,
        height: 1.0, color: color,
      );

  /// Caption — 12px / Medium
  static TextStyle caption({Color? color}) => _inter(
        size: 12, weight: FontWeight.w500, letterSpacing: 0.5,
        height: 1.4, color: color,
      );

  /// Overline — 11px / Medium / uppercase
  static TextStyle overline({Color? color}) => _inter(
        size: 11, weight: FontWeight.w500, letterSpacing: 1.5,
        height: 1.4, color: color,
      );

  /// Code / monospace
  static TextStyle code({Color? color}) => TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.6,
        color: color,
      );

  // ── Table ────────────────────────────────────────────────────────────────────
  static TextStyle tableHeader({Color? color}) => _inter(
        size: 12, weight: FontWeight.w600, letterSpacing: 0.8,
        height: 1.4, color: color,
      );

  static TextStyle tableCell({Color? color}) => _inter(
        size: 13, weight: FontWeight.w400, letterSpacing: 0.15,
        height: 1.4, color: color,
      );

  // ── Stat / metric ────────────────────────────────────────────────────────────
  static TextStyle metric({Color? color}) => _inter(
        size: 36, weight: FontWeight.w700, letterSpacing: -1,
        height: 1.1, color: color,
      );
}
