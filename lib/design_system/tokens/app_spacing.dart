// =============================================================================
// FILE: lib/core/theme/app_spacing.dart
// PURPOSE: Spacing, border radius, elevation & layout tokens
// =============================================================================

import 'package:flutter/material.dart';

/// Spacing scale — based on 4px grid.
abstract final class AppSpacing {
  AppSpacing._();

  // ── Base unit ────────────────────────────────────────────────────────────────
  static const double _base = 4.0;

  // ── Spacing ──────────────────────────────────────────────────────────────────
  static const double xs   =  _base * 1;   //  4
  static const double sm   =  _base * 2;   //  8
  static const double md   =  _base * 3;   // 12
  static const double lg   =  _base * 4;   // 16
  static const double xl   =  _base * 6;   // 24
  static const double xl2  =  _base * 8;   // 32
  static const double xl3  =  _base * 10;  // 40
  static const double xl4  =  _base * 12;  // 48
  static const double xl5  =  _base * 16;  // 64
  static const double xl6  =  _base * 20;  // 80

  // ── Padding presets ──────────────────────────────────────────────────────────
  static const EdgeInsets paddingXs  = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm  = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd  = EdgeInsets.all(md);
  static const EdgeInsets paddingLg  = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl  = EdgeInsets.all(xl);

  static const EdgeInsets paddingHSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVLg = EdgeInsets.symmetric(vertical: lg);

  static const EdgeInsets cardPadding    = EdgeInsets.all(lg);         // 16
  static const EdgeInsets dialogPadding  = EdgeInsets.all(xl);         // 24
  static const EdgeInsets pagePadding    = EdgeInsets.all(xl);         // 24
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  // ── SizedBox gaps ────────────────────────────────────────────────────────────
  static const Widget gapXs  = SizedBox(width: xs,  height: xs);
  static const Widget gapSm  = SizedBox(width: sm,  height: sm);
  static const Widget gapMd  = SizedBox(width: md,  height: md);
  static const Widget gapLg  = SizedBox(width: lg,  height: lg);
  static const Widget gapXl  = SizedBox(width: xl,  height: xl);
  static const Widget gapXl2 = SizedBox(width: xl2, height: xl2);

  static const Widget hGapXs  = SizedBox(width: xs);
  static const Widget hGapSm  = SizedBox(width: sm);
  static const Widget hGapMd  = SizedBox(width: md);
  static const Widget hGapLg  = SizedBox(width: lg);
  static const Widget hGapXl  = SizedBox(width: xl);

  static const Widget vGapXs  = SizedBox(height: xs);
  static const Widget vGapSm  = SizedBox(height: sm);
  static const Widget vGapMd  = SizedBox(height: md);
  static const Widget vGapLg  = SizedBox(height: lg);
  static const Widget vGapXl  = SizedBox(height: xl);
  static const Widget vGapXl2 = SizedBox(height: xl2);
  static const Widget vGapXl3 = SizedBox(height: xl3);
}

/// Border radius tokens — all UI elements should pull from here.
abstract final class AppRadius {
  AppRadius._();

  static const double none   = 0;
  static const double xs     = 4;
  static const double sm     = 6;
  static const double md     = 8;   // ← default
  static const double lg     = 12;
  static const double xl     = 16;
  static const double xl2    = 20;
  static const double xl3    = 24;
  static const double full   = 9999; // pill / circular

  // BorderRadius objects
  static const BorderRadius brNone  = BorderRadius.all(Radius.circular(none));
  static const BorderRadius brXs    = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm    = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd    = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg    = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl    = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brXl2   = BorderRadius.all(Radius.circular(xl2));
  static const BorderRadius brXl3   = BorderRadius.all(Radius.circular(xl3));
  static const BorderRadius brFull  = BorderRadius.all(Radius.circular(full));

  // Chip / Tag shape
  static final RoundedRectangleBorder chipShape = RoundedRectangleBorder(
    borderRadius: brFull,
  );

  // Card shape (matches Material 3 spec)
  static final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: brLg,
  );

  // Dialog shape
  static final RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: brXl,
  );

  // Bottom sheet
  static final RoundedRectangleBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft:  Radius.circular(xl2),
      topRight: Radius.circular(xl2),
    ),
  );
}

/// Elevation tokens — maps to Material 3 tonal elevation.
abstract final class AppElevation {
  AppElevation._();

  static const double none     = 0;
  static const double xs       = 1;
  static const double sm       = 2;
  static const double md       = 4;   // card default
  static const double lg       = 8;   // dropdown, tooltip
  static const double xl       = 12;  // modal
  static const double xl2      = 16;  // dialog
  static const double xl3      = 24;  // bottom sheet
}

/// Layout breakpoints for responsive web/tablet support.
abstract final class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile  = 480;
  static const double tablet  = 768;
  static const double laptop  = 1024;
  static const double desktop = 1280;
  static const double widescreen = 1536;

  // Sidebar widths
  static const double sidebarExpanded  = 260;
  static const double sidebarCollapsed = 72;

  // Content max width
  static const double contentMaxWidth  = 1200;
  static const double formMaxWidth     = 600;
}
