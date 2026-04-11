// =============================================================================
// FILE: lib/core/theme/app_theme_tokens.dart
// PURPOSE: Dynamic 50-token ThemeExtension for Vidyron School ERP
// Access in widgets: Theme.of(context).extension<AppThemeTokens>()!
// =============================================================================

import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    // Surface
    required this.surfaceBg,
    required this.cardBg,
    required this.sidebarBg,
    required this.topbarBg,
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textLink,
    // Primary
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.onPrimary,
    // Tables
    required this.tableHeaderBg,
    required this.tableHeaderText,
    required this.tableRowEvenBg,
    required this.tableRowOddBg,
    required this.tableBorder,
    required this.tableHoverBg,
    // Inputs
    required this.inputBg,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.inputLabel,
    // Buttons
    required this.buttonPrimaryBg,
    required this.buttonPrimaryText,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
    required this.buttonDangerBg,
    // Chips
    required this.chipActiveBg,
    required this.chipActiveText,
    required this.chipInactiveBg,
    // Status
    required this.successBg,
    required this.successText,
    required this.warningBg,
    required this.warningText,
    required this.errorBg,
    required this.errorText,
    required this.infoBg,
    required this.infoText,
    // Navigation
    required this.navItemBg,
    required this.navItemActiveBg,
    required this.navItemText,
    required this.navItemActiveText,
    required this.navItemIcon,
    required this.navItemActiveIcon,
    // Borders/Dividers
    required this.divider,
    required this.cardBorder,
    required this.shadowColor,
    // Shimmer
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  // Surface
  final Color surfaceBg;
  final Color cardBg;
  final Color sidebarBg;
  final Color topbarBg;
  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color textLink;
  // Primary
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color onPrimary;
  // Tables
  final Color tableHeaderBg;
  final Color tableHeaderText;
  final Color tableRowEvenBg;
  final Color tableRowOddBg;
  final Color tableBorder;
  final Color tableHoverBg;
  // Inputs
  final Color inputBg;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color inputLabel;
  // Buttons
  final Color buttonPrimaryBg;
  final Color buttonPrimaryText;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;
  final Color buttonDangerBg;
  // Chips
  final Color chipActiveBg;
  final Color chipActiveText;
  final Color chipInactiveBg;
  // Status
  final Color successBg;
  final Color successText;
  final Color warningBg;
  final Color warningText;
  final Color errorBg;
  final Color errorText;
  final Color infoBg;
  final Color infoText;
  // Navigation
  final Color navItemBg;
  final Color navItemActiveBg;
  final Color navItemText;
  final Color navItemActiveText;
  final Color navItemIcon;
  final Color navItemActiveIcon;
  // Borders/Dividers
  final Color divider;
  final Color cardBorder;
  final Color shadowColor;
  // Shimmer
  final Color shimmerBase;
  final Color shimmerHighlight;

  // ─── Default Light — Glassmorphism ─────────────────────────────────────────
  // Background image is globally blurred. Cards are blue-tinted frosted glass
  // (NOT white) — matching the reference design with visible blurred campus image.
  static const AppThemeTokens lightDefaults = AppThemeTokens(
    surfaceBg: Color(0x00000000),       // transparent — blurred background image shows through
    // Blue-100 (#DBEAFE) at 65% opacity → light blue frosted glass matching reference
    cardBg: Color(0xA8DBEAFE),
    sidebarBg: Color(0x26FFFFFF),        // BackdropFilter shell widgets override this
    topbarBg: Color(0x26FFFFFF),         // BackdropFilter shell widgets override this
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF1E3A6E),
    textHint: Color(0xFF64748B),
    textLink: Color(0xFF2563EB),
    primary: Color(0xFF2563EB),
    primaryLight: Color(0xFF60A5FA),
    primaryDark: Color(0xFF1D4ED8),
    onPrimary: Color(0xFFFFFFFF),
    // Blue-tinted table — header darker, rows more transparent
    tableHeaderBg: Color(0xC0BFDBFE),   // 75% blue-200 — clear header
    tableHeaderText: Color(0xFF1E3A8A),
    tableRowEvenBg: Color(0x80EFF6FF),  // 50% blue-50 — transparent even rows
    tableRowOddBg: Color(0x55DBEAFE),   // 33% blue-100 — even more transparent odd rows
    tableBorder: Color(0x60BFDBFE),     // soft blue border
    tableHoverBg: Color(0xAACBDCFF),
    inputBg: Color(0xF0FFFFFF),          // 94% white — inputs very opaque so labels always readable
    inputBorder: Color(0x90BFDBFE),
    inputFocusBorder: Color(0xFF2563EB),
    inputLabel: Color(0xFF1E3A6E),
    buttonPrimaryBg: Color(0xFF2563EB),
    buttonPrimaryText: Color(0xFFFFFFFF),
    buttonSecondaryBg: Color(0xAADBEAFE),
    buttonSecondaryText: Color(0xFF2563EB),
    buttonDangerBg: Color(0xFFE11D48),
    chipActiveBg: Color(0xCCDBEAFE),
    chipActiveText: Color(0xFF1E3A8A),
    chipInactiveBg: Color(0x88EFF6FF),
    successBg: Color(0xAAD1FAE5),
    successText: Color(0xFF047857),
    warningBg: Color(0xAAFEF3C7),
    warningText: Color(0xFFB45309),
    errorBg: Color(0xAAFFE4E6),
    errorText: Color(0xFFBE123C),
    infoBg: Color(0xAACFFAFE),
    infoText: Color(0xFF0E7490),
    navItemBg: Color(0x00000000),
    navItemActiveBg: Color(0x502563EB),  // 31% brand blue — glass active
    navItemText: Color(0xFF1E3A6E),
    navItemActiveText: Color(0xFF1E40AF),
    navItemIcon: Color(0xFF475569),
    navItemActiveIcon: Color(0xFF2563EB),
    divider: Color(0x60BFDBFE),          // blue divider
    cardBorder: Color(0x99FFFFFF),       // 60% white border — clearly visible glass rim
    shadowColor: Color(0x200F172A),      // very soft shadow
    shimmerBase: Color(0x88DBEAFE),
    shimmerHighlight: Color(0xBBEFF6FF),
  );

  // ─── Default Dark ───────────────────────────────────────────────────────────
  static const AppThemeTokens darkDefaults = AppThemeTokens(
    // Transparent scaffold — dark blurred background image shows through.
    // Cards are dark-glass panels that float over the midnight campus scene.
    surfaceBg:        Color(0x00000000),   // transparent — background bleeds through
    cardBg:           Color(0xCC0A1829),   // 80% dark navy glass
    sidebarBg:        Color(0xE8060D1C),   // 91% deepest sidebar
    topbarBg:         Color(0xE0060D1C),   // 88% topbar
    // Text
    textPrimary:      Color(0xFFF0F9FF),   // near-white with cool blue tint
    textSecondary:    Color(0xFF8AACCF),   // blue-gray secondary
    textHint:         Color(0xFF3D5F7A),   // muted hint
    textLink:         Color(0xFF60A5FA),   // electric blue
    // Primary
    primary:          Color(0xFF2563EB),   // vivid electric blue (reference image)
    primaryLight:     Color(0xFF60A5FA),   // bright sky blue
    primaryDark:      Color(0xFF1D4ED8),   // deep cobalt
    onPrimary:        Color(0xFFFFFFFF),
    // Tables — deep header, alternating glass rows
    tableHeaderBg:    Color(0xF00C1E38),   // 94% deep blue header
    tableHeaderText:  Color(0xFFBFDBFE),   // ice blue label
    tableRowEvenBg:   Color(0xD00A1829),   // 82% navy — even rows
    tableRowOddBg:    Color(0xC0060D1C),   // 75% midnight — odd rows
    tableBorder:      Color(0xFF0E2244),   // subtle border line
    tableHoverBg:     Color(0xFF162E52),   // hover highlight
    // Inputs
    inputBg:          Color(0xCC0A1829),   // dark glass input
    inputBorder:      Color(0xFF0E2244),
    inputFocusBorder: Color(0xFF2563EB),
    inputLabel:       Color(0xFF8AACCF),
    // Buttons
    buttonPrimaryBg:      Color(0xFF2563EB),
    buttonPrimaryText:    Color(0xFFFFFFFF),
    buttonSecondaryBg:    Color(0xFF0E2244),
    buttonSecondaryText:  Color(0xFF60A5FA),
    buttonDangerBg:       Color(0xFFBE123C),
    // Chips
    chipActiveBg:    Color(0xFF1E3A8A),
    chipActiveText:  Color(0xFFBFDBFE),
    chipInactiveBg:  Color(0xFF0E2244),
    // Status — vivid saturated tones matching reference
    successBg:    Color(0xFF052E1A),
    successText:  Color(0xFF34D399),   // bright emerald
    warningBg:    Color(0xFF431407),
    warningText:  Color(0xFFFBBF24),   // golden amber
    errorBg:      Color(0xFF4C0519),
    errorText:    Color(0xFFF87171),   // coral red
    infoBg:       Color(0xFF082030),
    infoText:     Color(0xFF38BDF8),   // sky cyan
    // Navigation
    navItemBg:          Color(0x00000000),
    navItemActiveBg:    Color(0x302563EB),   // 19% primary glow
    navItemText:        Color(0xFF6B93B8),
    navItemActiveText:  Color(0xFF93C5FD),
    navItemIcon:        Color(0xFF3D5F7A),
    navItemActiveIcon:  Color(0xFF60A5FA),
    // Borders / Dividers
    divider:      Color(0xFF0E2244),
    cardBorder:   Color(0xFF1A3860),   // blue-tinted glass rim
    shadowColor:  Color(0xFF000000),
    // Shimmer
    shimmerBase:      Color(0xFF0A1829),
    shimmerHighlight: Color(0xFF162E52),
  );

  // ─── Presets ────────────────────────────────────────────────────────────────
  static const Map<String, ({AppThemeTokens light, AppThemeTokens dark})> presets = {
    'Default': (light: lightDefaults, dark: darkDefaults),
    'Ocean Blue': (
      light: AppThemeTokens(
        surfaceBg: Color(0xFFE0F2FE),
        cardBg: Color(0xFFFFFFFF),
        sidebarBg: Color(0xFFFFFFFF),
        topbarBg: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF0C4A6E),
        textSecondary: Color(0xFF075985),
        textHint: Color(0xFF94A3B8),
        textLink: Color(0xFF0284C7),
        primary: Color(0xFF0284C7),
        primaryLight: Color(0xFF38BDF8),
        primaryDark: Color(0xFF0369A1),
        onPrimary: Color(0xFFFFFFFF),
        tableHeaderBg: Color(0xFFE0F2FE),
        tableHeaderText: Color(0xFF0C4A6E),
        tableRowEvenBg: Color(0xFFFFFFFF),
        tableRowOddBg: Color(0xFFF0F9FF),
        tableBorder: Color(0xFFBAE6FD),
        tableHoverBg: Color(0xFFE0F2FE),
        inputBg: Color(0xFFFFFFFF),
        inputBorder: Color(0xFFBAE6FD),
        inputFocusBorder: Color(0xFF0284C7),
        inputLabel: Color(0xFF075985),
        buttonPrimaryBg: Color(0xFF0284C7),
        buttonPrimaryText: Color(0xFFFFFFFF),
        buttonSecondaryBg: Color(0xFFE0F2FE),
        buttonSecondaryText: Color(0xFF0284C7),
        buttonDangerBg: Color(0xFFE11D48),
        chipActiveBg: Color(0xFFE0F2FE),
        chipActiveText: Color(0xFF0C4A6E),
        chipInactiveBg: Color(0xFFF1F5F9),
        successBg: Color(0xFFECFDF5),
        successText: Color(0xFF047857),
        warningBg: Color(0xFFFFFBEB),
        warningText: Color(0xFFB45309),
        errorBg: Color(0xFFFFF1F2),
        errorText: Color(0xFFBE123C),
        infoBg: Color(0xFFECFEFF),
        infoText: Color(0xFF0E7490),
        navItemBg: Color(0x00000000),
        navItemActiveBg: Color(0xFFE0F2FE),
        navItemText: Color(0xFF075985),
        navItemActiveText: Color(0xFF0C4A6E),
        navItemIcon: Color(0xFF64748B),
        navItemActiveIcon: Color(0xFF0284C7),
        divider: Color(0xFFBAE6FD),
        cardBorder: Color(0xFFBAE6FD),
        shadowColor: Color(0xFF0C4A6E),
        shimmerBase: Color(0xFFE0F2FE),
        shimmerHighlight: Color(0xFFF0F9FF),
      ),
      dark: AppThemeTokens(
        surfaceBg: Color(0xFF0C1A2E),
        cardBg: Color(0xFF0F2845),
        sidebarBg: Color(0xFF091520),
        topbarBg: Color(0xFF091520),
        textPrimary: Color(0xFFE0F2FE),
        textSecondary: Color(0xFF7DD3FC),
        textHint: Color(0xFF38BDF8),
        textLink: Color(0xFF38BDF8),
        primary: Color(0xFF38BDF8),
        primaryLight: Color(0xFF7DD3FC),
        primaryDark: Color(0xFF0284C7),
        onPrimary: Color(0xFFFFFFFF),
        tableHeaderBg: Color(0xFF0C4A6E),
        tableHeaderText: Color(0xFFE0F2FE),
        tableRowEvenBg: Color(0xFF0F2845),
        tableRowOddBg: Color(0xFF091520),
        tableBorder: Color(0xFF075985),
        tableHoverBg: Color(0xFF075985),
        inputBg: Color(0xFF0F2845),
        inputBorder: Color(0xFF075985),
        inputFocusBorder: Color(0xFF38BDF8),
        inputLabel: Color(0xFF7DD3FC),
        buttonPrimaryBg: Color(0xFF0284C7),
        buttonPrimaryText: Color(0xFFFFFFFF),
        buttonSecondaryBg: Color(0xFF0C4A6E),
        buttonSecondaryText: Color(0xFF38BDF8),
        buttonDangerBg: Color(0xFFBE123C),
        chipActiveBg: Color(0xFF0C4A6E),
        chipActiveText: Color(0xFFE0F2FE),
        chipInactiveBg: Color(0xFF075985),
        successBg: Color(0xFF064E3B),
        successText: Color(0xFF6EE7B7),
        warningBg: Color(0xFF78350F),
        warningText: Color(0xFFFCD34D),
        errorBg: Color(0xFF881337),
        errorText: Color(0xFFFDA4AF),
        infoBg: Color(0xFF164E63),
        infoText: Color(0xFF67E8F9),
        navItemBg: Color(0x00000000),
        navItemActiveBg: Color(0xFF0C4A6E),
        navItemText: Color(0xFF7DD3FC),
        navItemActiveText: Color(0xFFE0F2FE),
        navItemIcon: Color(0xFF38BDF8),
        navItemActiveIcon: Color(0xFF7DD3FC),
        divider: Color(0xFF075985),
        cardBorder: Color(0xFF075985),
        shadowColor: Color(0xFF000000),
        shimmerBase: Color(0xFF0C4A6E),
        shimmerHighlight: Color(0xFF075985),
      ),
    ),
    'Emerald Green': (
      light: AppThemeTokens(
        surfaceBg: Color(0xFFECFDF5),
        cardBg: Color(0xFFFFFFFF),
        sidebarBg: Color(0xFFFFFFFF),
        topbarBg: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF064E3B),
        textSecondary: Color(0xFF065F46),
        textHint: Color(0xFF94A3B8),
        textLink: Color(0xFF059669),
        primary: Color(0xFF059669),
        primaryLight: Color(0xFF34D399),
        primaryDark: Color(0xFF047857),
        onPrimary: Color(0xFFFFFFFF),
        tableHeaderBg: Color(0xFFD1FAE5),
        tableHeaderText: Color(0xFF064E3B),
        tableRowEvenBg: Color(0xFFFFFFFF),
        tableRowOddBg: Color(0xFFF0FDF4),
        tableBorder: Color(0xFFA7F3D0),
        tableHoverBg: Color(0xFFD1FAE5),
        inputBg: Color(0xFFFFFFFF),
        inputBorder: Color(0xFFA7F3D0),
        inputFocusBorder: Color(0xFF059669),
        inputLabel: Color(0xFF065F46),
        buttonPrimaryBg: Color(0xFF059669),
        buttonPrimaryText: Color(0xFFFFFFFF),
        buttonSecondaryBg: Color(0xFFD1FAE5),
        buttonSecondaryText: Color(0xFF059669),
        buttonDangerBg: Color(0xFFE11D48),
        chipActiveBg: Color(0xFFD1FAE5),
        chipActiveText: Color(0xFF064E3B),
        chipInactiveBg: Color(0xFFF1F5F9),
        successBg: Color(0xFFECFDF5),
        successText: Color(0xFF047857),
        warningBg: Color(0xFFFFFBEB),
        warningText: Color(0xFFB45309),
        errorBg: Color(0xFFFFF1F2),
        errorText: Color(0xFFBE123C),
        infoBg: Color(0xFFECFEFF),
        infoText: Color(0xFF0E7490),
        navItemBg: Color(0x00000000),
        navItemActiveBg: Color(0xFFD1FAE5),
        navItemText: Color(0xFF065F46),
        navItemActiveText: Color(0xFF064E3B),
        navItemIcon: Color(0xFF64748B),
        navItemActiveIcon: Color(0xFF059669),
        divider: Color(0xFFA7F3D0),
        cardBorder: Color(0xFFA7F3D0),
        shadowColor: Color(0xFF064E3B),
        shimmerBase: Color(0xFFD1FAE5),
        shimmerHighlight: Color(0xFFF0FDF4),
      ),
      dark: darkDefaults,
    ),
    'Crimson Red': (
      light: AppThemeTokens(
        surfaceBg: Color(0xFFFFF5F5),
        cardBg: Color(0xFFFFFFFF),
        sidebarBg: Color(0xFFFFFFFF),
        topbarBg: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF7F1D1D),
        textSecondary: Color(0xFF991B1B),
        textHint: Color(0xFF94A3B8),
        textLink: Color(0xFFDC2626),
        primary: Color(0xFFDC2626),
        primaryLight: Color(0xFFF87171),
        primaryDark: Color(0xFFB91C1C),
        onPrimary: Color(0xFFFFFFFF),
        tableHeaderBg: Color(0xFFFEE2E2),
        tableHeaderText: Color(0xFF7F1D1D),
        tableRowEvenBg: Color(0xFFFFFFFF),
        tableRowOddBg: Color(0xFFFFF5F5),
        tableBorder: Color(0xFFFECACA),
        tableHoverBg: Color(0xFFFEE2E2),
        inputBg: Color(0xFFFFFFFF),
        inputBorder: Color(0xFFFECACA),
        inputFocusBorder: Color(0xFFDC2626),
        inputLabel: Color(0xFF991B1B),
        buttonPrimaryBg: Color(0xFFDC2626),
        buttonPrimaryText: Color(0xFFFFFFFF),
        buttonSecondaryBg: Color(0xFFFEE2E2),
        buttonSecondaryText: Color(0xFFDC2626),
        buttonDangerBg: Color(0xFF7F1D1D),
        chipActiveBg: Color(0xFFFEE2E2),
        chipActiveText: Color(0xFF7F1D1D),
        chipInactiveBg: Color(0xFFF1F5F9),
        successBg: Color(0xFFECFDF5),
        successText: Color(0xFF047857),
        warningBg: Color(0xFFFFFBEB),
        warningText: Color(0xFFB45309),
        errorBg: Color(0xFFFFF1F2),
        errorText: Color(0xFFBE123C),
        infoBg: Color(0xFFECFEFF),
        infoText: Color(0xFF0E7490),
        navItemBg: Color(0x00000000),
        navItemActiveBg: Color(0xFFFEE2E2),
        navItemText: Color(0xFF991B1B),
        navItemActiveText: Color(0xFF7F1D1D),
        navItemIcon: Color(0xFF64748B),
        navItemActiveIcon: Color(0xFFDC2626),
        divider: Color(0xFFFECACA),
        cardBorder: Color(0xFFFECACA),
        shadowColor: Color(0xFF7F1D1D),
        shimmerBase: Color(0xFFFEE2E2),
        shimmerHighlight: Color(0xFFFFF5F5),
      ),
      dark: darkDefaults,
    ),
    'Slate Gray': (
      light: AppThemeTokens(
        surfaceBg: Color(0xFFF1F5F9),
        cardBg: Color(0xFFFFFFFF),
        sidebarBg: Color(0xFFFFFFFF),
        topbarBg: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF1E293B),
        textSecondary: Color(0xFF334155),
        textHint: Color(0xFF94A3B8),
        textLink: Color(0xFF475569),
        primary: Color(0xFF475569),
        primaryLight: Color(0xFF94A3B8),
        primaryDark: Color(0xFF334155),
        onPrimary: Color(0xFFFFFFFF),
        tableHeaderBg: Color(0xFFF1F5F9),
        tableHeaderText: Color(0xFF1E293B),
        tableRowEvenBg: Color(0xFFFFFFFF),
        tableRowOddBg: Color(0xFFF8FAFC),
        tableBorder: Color(0xFFCBD5E1),
        tableHoverBg: Color(0xFFE2E8F0),
        inputBg: Color(0xFFFFFFFF),
        inputBorder: Color(0xFFCBD5E1),
        inputFocusBorder: Color(0xFF475569),
        inputLabel: Color(0xFF334155),
        buttonPrimaryBg: Color(0xFF475569),
        buttonPrimaryText: Color(0xFFFFFFFF),
        buttonSecondaryBg: Color(0xFFE2E8F0),
        buttonSecondaryText: Color(0xFF475569),
        buttonDangerBg: Color(0xFFE11D48),
        chipActiveBg: Color(0xFFE2E8F0),
        chipActiveText: Color(0xFF1E293B),
        chipInactiveBg: Color(0xFFF1F5F9),
        successBg: Color(0xFFECFDF5),
        successText: Color(0xFF047857),
        warningBg: Color(0xFFFFFBEB),
        warningText: Color(0xFFB45309),
        errorBg: Color(0xFFFFF1F2),
        errorText: Color(0xFFBE123C),
        infoBg: Color(0xFFECFEFF),
        infoText: Color(0xFF0E7490),
        navItemBg: Color(0x00000000),
        navItemActiveBg: Color(0xFFE2E8F0),
        navItemText: Color(0xFF334155),
        navItemActiveText: Color(0xFF1E293B),
        navItemIcon: Color(0xFF64748B),
        navItemActiveIcon: Color(0xFF475569),
        divider: Color(0xFFCBD5E1),
        cardBorder: Color(0xFFCBD5E1),
        shadowColor: Color(0xFF1E293B),
        shimmerBase: Color(0xFFE2E8F0),
        shimmerHighlight: Color(0xFFF8FAFC),
      ),
      dark: darkDefaults,
    ),
  };

  // ─── JSON helpers ───────────────────────────────────────────────────────────
  static Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h == 'transparent' || h == '00000000') return const Color(0x00000000);
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return const Color(0xFF000000);
  }

  static String _colorToHex(Color c) {
    final a = (c.a * 255).round().toRadixString(16).padLeft(2, '0');
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$a$r$g$b';
  }

  factory AppThemeTokens.fromJson(Map<String, dynamic> json) {
    Color c(String key, Color fallback) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return _hexToColor(v);
      return fallback;
    }
    const d = lightDefaults;
    return AppThemeTokens(
      surfaceBg: c('surfaceBg', d.surfaceBg),
      cardBg: c('cardBg', d.cardBg),
      sidebarBg: c('sidebarBg', d.sidebarBg),
      topbarBg: c('topbarBg', d.topbarBg),
      textPrimary: c('textPrimary', d.textPrimary),
      textSecondary: c('textSecondary', d.textSecondary),
      textHint: c('textHint', d.textHint),
      textLink: c('textLink', d.textLink),
      primary: c('primary', d.primary),
      primaryLight: c('primaryLight', d.primaryLight),
      primaryDark: c('primaryDark', d.primaryDark),
      onPrimary: c('onPrimary', d.onPrimary),
      tableHeaderBg: c('tableHeaderBg', d.tableHeaderBg),
      tableHeaderText: c('tableHeaderText', d.tableHeaderText),
      tableRowEvenBg: c('tableRowEvenBg', d.tableRowEvenBg),
      tableRowOddBg: c('tableRowOddBg', d.tableRowOddBg),
      tableBorder: c('tableBorder', d.tableBorder),
      tableHoverBg: c('tableHoverBg', d.tableHoverBg),
      inputBg: c('inputBg', d.inputBg),
      inputBorder: c('inputBorder', d.inputBorder),
      inputFocusBorder: c('inputFocusBorder', d.inputFocusBorder),
      inputLabel: c('inputLabel', d.inputLabel),
      buttonPrimaryBg: c('buttonPrimaryBg', d.buttonPrimaryBg),
      buttonPrimaryText: c('buttonPrimaryText', d.buttonPrimaryText),
      buttonSecondaryBg: c('buttonSecondaryBg', d.buttonSecondaryBg),
      buttonSecondaryText: c('buttonSecondaryText', d.buttonSecondaryText),
      buttonDangerBg: c('buttonDangerBg', d.buttonDangerBg),
      chipActiveBg: c('chipActiveBg', d.chipActiveBg),
      chipActiveText: c('chipActiveText', d.chipActiveText),
      chipInactiveBg: c('chipInactiveBg', d.chipInactiveBg),
      successBg: c('successBg', d.successBg),
      successText: c('successText', d.successText),
      warningBg: c('warningBg', d.warningBg),
      warningText: c('warningText', d.warningText),
      errorBg: c('errorBg', d.errorBg),
      errorText: c('errorText', d.errorText),
      infoBg: c('infoBg', d.infoBg),
      infoText: c('infoText', d.infoText),
      navItemBg: c('navItemBg', d.navItemBg),
      navItemActiveBg: c('navItemActiveBg', d.navItemActiveBg),
      navItemText: c('navItemText', d.navItemText),
      navItemActiveText: c('navItemActiveText', d.navItemActiveText),
      navItemIcon: c('navItemIcon', d.navItemIcon),
      navItemActiveIcon: c('navItemActiveIcon', d.navItemActiveIcon),
      divider: c('divider', d.divider),
      cardBorder: c('cardBorder', d.cardBorder),
      shadowColor: c('shadowColor', d.shadowColor),
      shimmerBase: c('shimmerBase', d.shimmerBase),
      shimmerHighlight: c('shimmerHighlight', d.shimmerHighlight),
    );
  }

  Map<String, dynamic> toJson() => {
    'surfaceBg': _colorToHex(surfaceBg),
    'cardBg': _colorToHex(cardBg),
    'sidebarBg': _colorToHex(sidebarBg),
    'topbarBg': _colorToHex(topbarBg),
    'textPrimary': _colorToHex(textPrimary),
    'textSecondary': _colorToHex(textSecondary),
    'textHint': _colorToHex(textHint),
    'textLink': _colorToHex(textLink),
    'primary': _colorToHex(primary),
    'primaryLight': _colorToHex(primaryLight),
    'primaryDark': _colorToHex(primaryDark),
    'onPrimary': _colorToHex(onPrimary),
    'tableHeaderBg': _colorToHex(tableHeaderBg),
    'tableHeaderText': _colorToHex(tableHeaderText),
    'tableRowEvenBg': _colorToHex(tableRowEvenBg),
    'tableRowOddBg': _colorToHex(tableRowOddBg),
    'tableBorder': _colorToHex(tableBorder),
    'tableHoverBg': _colorToHex(tableHoverBg),
    'inputBg': _colorToHex(inputBg),
    'inputBorder': _colorToHex(inputBorder),
    'inputFocusBorder': _colorToHex(inputFocusBorder),
    'inputLabel': _colorToHex(inputLabel),
    'buttonPrimaryBg': _colorToHex(buttonPrimaryBg),
    'buttonPrimaryText': _colorToHex(buttonPrimaryText),
    'buttonSecondaryBg': _colorToHex(buttonSecondaryBg),
    'buttonSecondaryText': _colorToHex(buttonSecondaryText),
    'buttonDangerBg': _colorToHex(buttonDangerBg),
    'chipActiveBg': _colorToHex(chipActiveBg),
    'chipActiveText': _colorToHex(chipActiveText),
    'chipInactiveBg': _colorToHex(chipInactiveBg),
    'successBg': _colorToHex(successBg),
    'successText': _colorToHex(successText),
    'warningBg': _colorToHex(warningBg),
    'warningText': _colorToHex(warningText),
    'errorBg': _colorToHex(errorBg),
    'errorText': _colorToHex(errorText),
    'infoBg': _colorToHex(infoBg),
    'infoText': _colorToHex(infoText),
    'navItemBg': _colorToHex(navItemBg),
    'navItemActiveBg': _colorToHex(navItemActiveBg),
    'navItemText': _colorToHex(navItemText),
    'navItemActiveText': _colorToHex(navItemActiveText),
    'navItemIcon': _colorToHex(navItemIcon),
    'navItemActiveIcon': _colorToHex(navItemActiveIcon),
    'divider': _colorToHex(divider),
    'cardBorder': _colorToHex(cardBorder),
    'shadowColor': _colorToHex(shadowColor),
    'shimmerBase': _colorToHex(shimmerBase),
    'shimmerHighlight': _colorToHex(shimmerHighlight),
  };

  // ─── ThemeExtension overrides ────────────────────────────────────────────────
  @override
  AppThemeTokens copyWith({
    Color? surfaceBg, Color? cardBg, Color? sidebarBg, Color? topbarBg,
    Color? textPrimary, Color? textSecondary, Color? textHint, Color? textLink,
    Color? primary, Color? primaryLight, Color? primaryDark, Color? onPrimary,
    Color? tableHeaderBg, Color? tableHeaderText, Color? tableRowEvenBg,
    Color? tableRowOddBg, Color? tableBorder, Color? tableHoverBg,
    Color? inputBg, Color? inputBorder, Color? inputFocusBorder, Color? inputLabel,
    Color? buttonPrimaryBg, Color? buttonPrimaryText, Color? buttonSecondaryBg,
    Color? buttonSecondaryText, Color? buttonDangerBg,
    Color? chipActiveBg, Color? chipActiveText, Color? chipInactiveBg,
    Color? successBg, Color? successText, Color? warningBg, Color? warningText,
    Color? errorBg, Color? errorText, Color? infoBg, Color? infoText,
    Color? navItemBg, Color? navItemActiveBg, Color? navItemText,
    Color? navItemActiveText, Color? navItemIcon, Color? navItemActiveIcon,
    Color? divider, Color? cardBorder, Color? shadowColor,
    Color? shimmerBase, Color? shimmerHighlight,
  }) => AppThemeTokens(
    surfaceBg: surfaceBg ?? this.surfaceBg,
    cardBg: cardBg ?? this.cardBg,
    sidebarBg: sidebarBg ?? this.sidebarBg,
    topbarBg: topbarBg ?? this.topbarBg,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textHint: textHint ?? this.textHint,
    textLink: textLink ?? this.textLink,
    primary: primary ?? this.primary,
    primaryLight: primaryLight ?? this.primaryLight,
    primaryDark: primaryDark ?? this.primaryDark,
    onPrimary: onPrimary ?? this.onPrimary,
    tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
    tableHeaderText: tableHeaderText ?? this.tableHeaderText,
    tableRowEvenBg: tableRowEvenBg ?? this.tableRowEvenBg,
    tableRowOddBg: tableRowOddBg ?? this.tableRowOddBg,
    tableBorder: tableBorder ?? this.tableBorder,
    tableHoverBg: tableHoverBg ?? this.tableHoverBg,
    inputBg: inputBg ?? this.inputBg,
    inputBorder: inputBorder ?? this.inputBorder,
    inputFocusBorder: inputFocusBorder ?? this.inputFocusBorder,
    inputLabel: inputLabel ?? this.inputLabel,
    buttonPrimaryBg: buttonPrimaryBg ?? this.buttonPrimaryBg,
    buttonPrimaryText: buttonPrimaryText ?? this.buttonPrimaryText,
    buttonSecondaryBg: buttonSecondaryBg ?? this.buttonSecondaryBg,
    buttonSecondaryText: buttonSecondaryText ?? this.buttonSecondaryText,
    buttonDangerBg: buttonDangerBg ?? this.buttonDangerBg,
    chipActiveBg: chipActiveBg ?? this.chipActiveBg,
    chipActiveText: chipActiveText ?? this.chipActiveText,
    chipInactiveBg: chipInactiveBg ?? this.chipInactiveBg,
    successBg: successBg ?? this.successBg,
    successText: successText ?? this.successText,
    warningBg: warningBg ?? this.warningBg,
    warningText: warningText ?? this.warningText,
    errorBg: errorBg ?? this.errorBg,
    errorText: errorText ?? this.errorText,
    infoBg: infoBg ?? this.infoBg,
    infoText: infoText ?? this.infoText,
    navItemBg: navItemBg ?? this.navItemBg,
    navItemActiveBg: navItemActiveBg ?? this.navItemActiveBg,
    navItemText: navItemText ?? this.navItemText,
    navItemActiveText: navItemActiveText ?? this.navItemActiveText,
    navItemIcon: navItemIcon ?? this.navItemIcon,
    navItemActiveIcon: navItemActiveIcon ?? this.navItemActiveIcon,
    divider: divider ?? this.divider,
    cardBorder: cardBorder ?? this.cardBorder,
    shadowColor: shadowColor ?? this.shadowColor,
    shimmerBase: shimmerBase ?? this.shimmerBase,
    shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
  );

  @override
  AppThemeTokens lerp(AppThemeTokens? other, double t) {
    if (other == null) return this;
    return AppThemeTokens(
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      topbarBg: Color.lerp(topbarBg, other.topbarBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t)!,
      tableHeaderText: Color.lerp(tableHeaderText, other.tableHeaderText, t)!,
      tableRowEvenBg: Color.lerp(tableRowEvenBg, other.tableRowEvenBg, t)!,
      tableRowOddBg: Color.lerp(tableRowOddBg, other.tableRowOddBg, t)!,
      tableBorder: Color.lerp(tableBorder, other.tableBorder, t)!,
      tableHoverBg: Color.lerp(tableHoverBg, other.tableHoverBg, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusBorder: Color.lerp(inputFocusBorder, other.inputFocusBorder, t)!,
      inputLabel: Color.lerp(inputLabel, other.inputLabel, t)!,
      buttonPrimaryBg: Color.lerp(buttonPrimaryBg, other.buttonPrimaryBg, t)!,
      buttonPrimaryText: Color.lerp(buttonPrimaryText, other.buttonPrimaryText, t)!,
      buttonSecondaryBg: Color.lerp(buttonSecondaryBg, other.buttonSecondaryBg, t)!,
      buttonSecondaryText: Color.lerp(buttonSecondaryText, other.buttonSecondaryText, t)!,
      buttonDangerBg: Color.lerp(buttonDangerBg, other.buttonDangerBg, t)!,
      chipActiveBg: Color.lerp(chipActiveBg, other.chipActiveBg, t)!,
      chipActiveText: Color.lerp(chipActiveText, other.chipActiveText, t)!,
      chipInactiveBg: Color.lerp(chipInactiveBg, other.chipInactiveBg, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      navItemBg: Color.lerp(navItemBg, other.navItemBg, t)!,
      navItemActiveBg: Color.lerp(navItemActiveBg, other.navItemActiveBg, t)!,
      navItemText: Color.lerp(navItemText, other.navItemText, t)!,
      navItemActiveText: Color.lerp(navItemActiveText, other.navItemActiveText, t)!,
      navItemIcon: Color.lerp(navItemIcon, other.navItemIcon, t)!,
      navItemActiveIcon: Color.lerp(navItemActiveIcon, other.navItemActiveIcon, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}
