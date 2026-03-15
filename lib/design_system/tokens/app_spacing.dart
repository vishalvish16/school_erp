// =============================================================================
// FILE: lib/core/theme/app_spacing.dart
// PURPOSE: Spacing, border radius, elevation & layout tokens
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';

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

  static const double mobile     = 480;
  static const double tablet     = 768;
  static const double laptop     = 1024;
  static const double desktop    = 1280;
  static const double widescreen = 1536;

  // Sidebar widths
  static const double sidebarExpanded  = 260;
  static const double sidebarCollapsed = 72;

  // Content max widths — use these for ConstrainedBox / Container maxWidth
  static const double contentMaxWidth = 1200;
  static const double formMaxWidth    = 600;
  static const double dialogMaxWidth  = 560;
  static const double dialogMinWidth  = 400;
  static const double cardMinWidth    = 280;
}

// =============================================================================
// ICON SIZES — use AppIconSize everywhere instead of Icon(x, size: 24)
// =============================================================================

/// Icon size tokens — covers all icon usages across the system.
/// Never use raw numbers like `Icon(Icons.add, size: 24)`.
abstract final class AppIconSize {
  AppIconSize._();

  static const double xs  = 12.0;  // badge icon, tiny indicator
  static const double sm  = 16.0;  // inline icon in text, table row icon
  static const double md  = 20.0;  // button icon, form icon
  static const double lg  = 24.0;  // standard action icon (default)
  static const double xl  = 32.0;  // section header icon, card icon
  static const double xl2 = 40.0;  // avatar icon, large action
  static const double xl3 = 48.0;  // empty state icon
  static const double xl4 = 64.0;  // splash / error state icon
}

// =============================================================================
// BORDER WIDTH — use AppBorderWidth instead of raw 1.0, 1.5, 2.0
// =============================================================================

/// Border width tokens.
/// Never write `Border.all(width: 1)` or `side: BorderSide(width: 2)` inline.
abstract final class AppBorderWidth {
  AppBorderWidth._();

  static const double hairline = 0.5;  // very subtle separator
  static const double thin     = 1.0;  // default border
  static const double medium   = 1.5;  // focused / active border
  static const double thick    = 2.0;  // emphasis border, selected state
}

// =============================================================================
// OPACITY — use AppOpacity instead of raw .withValues(alpha: 0.5)
// =============================================================================

/// Opacity tokens — covers disabled states, overlays, hover states.
/// Use as: `color.withValues(alpha: AppOpacity.disabled)`
abstract final class AppOpacity {
  AppOpacity._();

  static const double hover    = 0.06;  // hover overlay on surfaces
  static const double pressed  = 0.10;  // pressed overlay on surfaces
  static const double focus    = 0.12;  // focused ring / overlay
  static const double divider  = 0.12;  // subtle divider alpha
  static const double disabled = 0.38;  // disabled text / icon
  static const double medium   = 0.50;  // medium visibility
  static const double high     = 0.70;  // high visibility secondary
  static const double shadow   = 0.08;  // standard box shadow alpha
  static const double overlay  = 0.40;  // modal overlay / scrim
  static const double scrim    = 0.60;  // full-screen scrim
}

// =============================================================================
// ANIMATION DURATION — use AppDuration instead of Duration(milliseconds: 200)
// =============================================================================

/// Animation duration tokens — keeps all transitions consistent.
/// Never write `Duration(milliseconds: 300)` or `Duration(seconds: 3)` inline.
abstract final class AppDuration {
  AppDuration._();

  static const Duration instant  = Duration(milliseconds: 50);    // micro-interaction
  static const Duration fast     = Duration(milliseconds: 150);   // button press
  static const Duration normal   = Duration(milliseconds: 250);   // standard transition
  static const Duration moderate = Duration(milliseconds: 350);   // dialog open/close
  static const Duration slow     = Duration(milliseconds: 500);   // page transition
  static const Duration xslow    = Duration(milliseconds: 800);   // splash / intro
  static const Duration toast    = Duration(seconds: 3);          // snackbar/toast display
  static const Duration tooltip  = Duration(milliseconds: 1500);  // tooltip auto-dismiss
}

// =============================================================================
// DIVIDER — pre-built Divider widgets using design system values
// =============================================================================

/// Pre-built dividers — use these instead of `Divider(color: ..., height: ...)`
abstract final class AppDivider {
  AppDivider._();

  /// Horizontal divider — standard 1px, subtle neutral color
  static Widget get horizontal => const _AppHDivider();

  /// Thin horizontal hairline divider
  static Widget get hairline => const _AppHDivider(hairline: true);

  /// Vertical divider (use inside Row)
  static Widget get vertical => const _AppVDivider();
}

class _AppHDivider extends StatelessWidget {
  const _AppHDivider({this.hairline = false});
  final bool hairline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: AppBorderWidth.thin,
      thickness: hairline ? AppBorderWidth.hairline : AppBorderWidth.thin,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: AppOpacity.medium),
    );
  }
}

class _AppVDivider extends StatelessWidget {
  const _AppVDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VerticalDivider(
      width: AppBorderWidth.thin,
      thickness: AppBorderWidth.thin,
      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: AppOpacity.medium),
    );
  }
}
