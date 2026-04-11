// =============================================================================
// FILE: lib/core/theme/theme.dart
// PURPOSE: Master ThemeData factory + ThemeNotifier for light/dark switching
//          Global widgets: AppLoader, AppSnackbar
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'app_input_styles.dart';
import 'app_card_styles.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';
export 'app_button_styles.dart';
export 'app_input_styles.dart';
export 'app_card_styles.dart';

// =============================================================================
// THEME NOTIFIER (state management-agnostic)
// Wrap with your preferred provider (Provider / Riverpod / Bloc / etc.)
// =============================================================================

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({ThemeMode initial = ThemeMode.system}) : _mode = initial;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;
  bool get isSystem => _mode == ThemeMode.system;

  void setLight() => _set(ThemeMode.light);
  void setDark() => _set(ThemeMode.dark);
  void setSystem() => _set(ThemeMode.system);

  void toggle() =>
      _set(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  void _set(ThemeMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
  }
}

// =============================================================================
// APP THEME FACTORY
// =============================================================================

abstract final class AppTheme {
  AppTheme._();

  // ── Public entry points ────────────────────────────────────────────────────

  static ThemeData get light => _build(AppColors.lightScheme);
  static ThemeData get dark => _build(AppColors.darkScheme);

  // ── Core builder ──────────────────────────────────────────────────────────

  static ThemeData _build(ColorScheme scheme) {
    final textTheme = buildInterTextTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,

      // ── Scaffold ──────────────────────────────────────────────────────────
      // Light: #B8CCE4 medium brand blue-grey — white cards pop clearly off it
      // Dark:  #07111F deep brand navy
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground   // #07111F — deep brand navy
          : AppColors.lightBackground, // #B8CCE4 — medium brand blue-grey

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.brandNavy900   // #0A1628 — dark navy topbar
            : AppColors.lightSurface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: AppElevation.xs,
        shadowColor: scheme.shadow.withAlpha(30),
        centerTitle: false,
        titleTextStyle: AppTextStyles.h5(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        toolbarHeight: 64,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: buildCardTheme(scheme),

      // ── Input / TextField ─────────────────────────────────────────────────
      inputDecorationTheme: AppInputStyles.inputDecorationTheme(scheme),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withAlpha(50),
        selectionHandleColor: scheme.primary,
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      // Use scheme.primary so dark mode gets bright blue, light mode gets brand blue
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: AppColors.neutral200,
          disabledForegroundColor: AppColors.neutral400,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          elevation: AppElevation.xs,
          shadowColor: scheme.primary.withAlpha(60),
          textStyle: AppTextStyles.buttonLabel(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return Colors.white.withAlpha(25);
            if (s.contains(WidgetState.pressed)) return Colors.white.withAlpha(40);
            return null;
          }),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: AppColors.neutral400,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.buttonLabel(),
          side: BorderSide(color: scheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return scheme.primary.withAlpha(15);
            if (s.contains(WidgetState.pressed)) return scheme.primary.withAlpha(25);
            return null;
          }),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          disabledForegroundColor: AppColors.neutral400,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.buttonLabel(),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return scheme.primary.withAlpha(12);
            if (s.contains(WidgetState.pressed)) return scheme.primary.withAlpha(20);
            return null;
          }),
        ),
      ),

      // ── FilledButton (M3) ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: AppTextStyles.buttonLabel(),
        ),
      ),

      // ── IconButton ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          minimumSize: const Size(40, 40),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        elevation: AppElevation.md,
      ),

      // ── Checkbox ─────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      // ── Radio ─────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant;
        }),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withAlpha(50),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withAlpha(30),
        trackHeight: 4,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outline.withAlpha(80),
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shadowColor: scheme.shadow.withAlpha(60),
        shape: AppRadius.dialogShape,
        titleTextStyle: AppTextStyles.h4(color: scheme.onSurface),
        contentTextStyle: AppTextStyles.body(color: scheme.onSurface),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl3,
        shape: AppRadius.bottomSheetShape,
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withAlpha(80),
        modalBackgroundColor: scheme.surface,
        modalBarrierColor: AppColors.scrim,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral900,
        contentTextStyle: AppTextStyles.body(color: Colors.white),
        actionTextColor: AppColors.primary300,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        elevation: AppElevation.lg,
        width: 480,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurfaceVar
            : AppColors.neutral100,
        selectedColor: scheme.primaryContainer,
        labelStyle: AppTextStyles.caption(color: scheme.onSurface),
        secondaryLabelStyle: AppTextStyles.caption(
          color: scheme.onPrimaryContainer,
        ),
        side: BorderSide(color: scheme.outline.withAlpha(80), width: 1),
        shape: AppRadius.chipShape,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ── Tab ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: AppTextStyles.caption().copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.body(),
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outline.withAlpha(80),
      ),

      // ── NavigationRail (sidebar) ──────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 22,
        ),
        selectedLabelTextStyle: AppTextStyles.caption().copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: AppTextStyles.body(
          color: scheme.onSurfaceVariant,
        ),
        indicatorColor: scheme.primary.withAlpha(26),
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        elevation: 0,
        useIndicator: true,
        minWidth: AppBreakpoints.sidebarCollapsed,
      ),

      // ── NavigationDrawer ──────────────────────────────────────────────────
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.lightSurface,
        indicatorColor: scheme.primary.withAlpha(26),
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.bodyMd(color: scheme.primary);
          }
          return AppTextStyles.body(color: scheme.onSurface);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary, size: 22);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 22);
        }),
        elevation: 0,
        tileHeight: 52,
      ),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.sm,
        titleTextStyle: AppTextStyles.body(color: scheme.onSurface),
        subtitleTextStyle: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: AppTextStyles.body(
          color: scheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        iconColor: scheme.onSurfaceVariant,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primary.withAlpha(15),
      ),

      // ── DataTable ─────────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingTextStyle: AppTextStyles.tableHeader(
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
        dataTextStyle: AppTextStyles.tableCell(color: scheme.onSurface),
        headingRowColor: WidgetStateProperty.all(
          isDark ? AppColors.brandNavy900 : AppColors.lightSurfaceVar,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withAlpha(25);
          }
          return null;
        }),
        columnSpacing: AppSpacing.xl,
        horizontalMargin: AppSpacing.lg,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
        dividerThickness: 1,
        headingRowHeight: 48,
        checkboxHorizontalMargin: AppSpacing.lg,
      ),

      // ── PopupMenu ─────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.lg,
        shadowColor: scheme.shadow.withAlpha(60),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTextStyles.body(color: scheme.onSurface),
        labelTextStyle: WidgetStateProperty.all(
          AppTextStyles.body(color: scheme.onSurface),
        ),
        position: PopupMenuPosition.under,
        enableFeedback: true,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutral700 : AppColors.neutral800,
          borderRadius: AppRadius.brSm,
        ),
        textStyle: AppTextStyles.caption(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        waitDuration: const Duration(milliseconds: 600),
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withAlpha(40),
        circularTrackColor: scheme.primary.withAlpha(40),
        strokeWidth: 3,
      ),

      // ── Badge ─────────────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.error,
        textColor: scheme.onError,
        smallSize: 6,
        largeSize: 18,
        textStyle: AppTextStyles.caption(color: scheme.onError),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),

      // ── Material splash ───────────────────────────────────────────────────
      splashColor: scheme.primary.withAlpha(20),
      highlightColor: scheme.primary.withAlpha(10),
      hoverColor: scheme.primary.withAlpha(8),
    );
  }
}

// =============================================================================
// GLOBAL WIDGETS
// =============================================================================

// ── AppLoader — global circular loading indicator ────────────────────────────

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 36,
    this.color,
    this.strokeWidth = 3,
    this.label,
  });

  final double size;
  final Color? color;
  final double strokeWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.primary;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
        strokeCap: StrokeCap.round,
      ),
    );

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          AppSpacing.vGapMd,
          Text(
            label!,
            style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return indicator;
  }

  // Centered full-screen overlay loader
  static Widget centered({String? label, Color? color}) => Center(
    child: AppLoader(label: label, color: color),
  );

  // Full-viewport centered loader — use this as a page-level loading state.
  // Works correctly inside scroll views, columns, and flex layouts.
  static Widget screen() => const AppLoaderScreen();

  // Inline small loader (replaces a button label)
  static Widget inline({Color? color}) =>
      AppLoader(size: 18, strokeWidth: 2, color: color);
}

// ── AppLoaderScreen — full-viewport centered loader ───────────────────────────
// Use this as the page-level loading state. Works correctly inside
// SingleChildScrollView, Column, Expanded, and Scaffold body — on both
// web (wide) and mobile.

class AppLoaderScreen extends StatelessWidget {
  const AppLoaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Center fills its parent's full bounded space.
    // Always wrap with Expanded (in Column) or use as direct Scaffold body child.
    return const Center(child: CircularProgressIndicator());
  }
}

// ── AppSnackbar — standardized snackbar factory ──────────────────────────────

enum SnackbarVariant { info, success, warning, error }

abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarVariant variant = SnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final (color, icon) = switch (variant) {
      SnackbarVariant.success => (
        AppColors.success600,
        Icons.check_circle_rounded,
      ),
      SnackbarVariant.warning => (AppColors.warning500, Icons.warning_rounded),
      SnackbarVariant.error => (AppColors.error600, Icons.error_rounded),
      SnackbarVariant.info => (AppColors.primary400, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body(color: Colors.white),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: color,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static void success(
    BuildContext ctx,
    String msg, {
    String? action,
    VoidCallback? onAction,
  }) => show(
    ctx,
    message: msg,
    variant: SnackbarVariant.success,
    actionLabel: action,
    onAction: onAction,
  );

  static void error(
    BuildContext ctx,
    String msg, {
    String? action,
    VoidCallback? onAction,
  }) => show(
    ctx,
    message: msg,
    variant: SnackbarVariant.error,
    actionLabel: action,
    onAction: onAction,
  );

  static void warning(
    BuildContext ctx,
    String msg, {
    String? action,
    VoidCallback? onAction,
  }) => show(
    ctx,
    message: msg,
    variant: SnackbarVariant.warning,
    actionLabel: action,
    onAction: onAction,
  );

  static void info(
    BuildContext ctx,
    String msg, {
    String? action,
    VoidCallback? onAction,
  }) => show(
    ctx,
    message: msg,
    variant: SnackbarVariant.info,
    actionLabel: action,
    onAction: onAction,
  );
}

// ── AppDialogs — standardized confirmation / alert dialogs ───────────────────

abstract final class AppDialogs {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: cs.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
}
