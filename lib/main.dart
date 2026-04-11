// =============================================================================
// FILE: lib/main.dart
// PURPOSE: App entry point — Enterprise SaaS Architecture Wiring
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;

import 'core/theme/app_theme_tokens.dart';
import 'core/theme/theme_provider.dart';
import 'design_system/design_system.dart';
import 'routes/app_router.dart';
import 'shared/widgets/inactivity_wrapper.dart';
import 'features/driver/location/driver_location_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (web + mobile)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Suppress "message discarded" warning for key events sent before framework
  // is ready (known Flutter race: https://github.com/flutter/flutter/issues/125975)
  ui.channelBuffers.allowOverflow('flutter/keyevent', true);
  ui.channelBuffers.allowOverflow('flutter/keydata', true);

  // Initialize driver background location service only on Android/iOS
  // (flutter_background_service is not supported on web)
  if (!kIsWeb) {
    await DriverLocationService.initialize();
  }

  runApp(const ProviderScope(child: SaaSAppRoot()));
}

class SaaSAppRoot extends ConsumerStatefulWidget {
  const SaaSAppRoot({super.key});

  @override
  ConsumerState<SaaSAppRoot> createState() => _SaaSAppRootState();
}

class _SaaSAppRootState extends ConsumerState<SaaSAppRoot> {
  @override
  void initState() {
    super.initState();
    // Load saved theme from SharedPreferences cache + backend API on startup.
    // Cache is restored instantly; API update follows async in background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeConfigProvider.notifier).loadTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    return p.MultiProvider(
      providers: [
        p.ChangeNotifierProvider(
          create: (_) => ThemeNotifier(initial: ThemeMode.light),
        ),
      ],
      child: const SchoolErpAdminApp(),
    );
  }
}

/// Injects every [AppThemeTokens] value into the full [ThemeData] tree so that
/// ALL widgets — cards, tables, inputs, buttons, chips, dialogs, etc. — respond
/// to token changes with zero changes to individual screens.
ThemeData _withTokens(ThemeData base, AppThemeTokens t, {bool forceTransparentScaffold = false}) {
  final isDark = base.brightness == Brightness.dark;
  final cs = base.colorScheme.copyWith(
    primary:                 t.primary,
    onPrimary:               t.onPrimary,
    primaryContainer:        t.primaryLight.withValues(alpha: 0.25),
    onPrimaryContainer:      t.primaryDark,
    secondary:               t.primaryLight,
    onSecondary:             t.onPrimary,
    surface:                 t.cardBg,
    onSurface:               t.textPrimary,
    onSurfaceVariant:        t.textSecondary,
    surfaceContainerLowest:  t.surfaceBg,
    surfaceContainerLow:     t.surfaceBg,
    surfaceContainer:        t.tableRowOddBg,
    surfaceContainerHigh:    t.tableRowEvenBg,
    surfaceContainerHighest: t.tableHeaderBg,
    outline:                 t.divider,
    outlineVariant:          t.divider.withValues(alpha: 0.5),
    error:                   t.errorText,
    onError:                 t.onPrimary,
    shadow:                  t.shadowColor,
  );

  return base.copyWith(
    colorScheme:             cs,
    // forceTransparentScaffold: light mode always transparent so the gradient
    // in the builder shows through every Scaffold, regardless of cached tokens.
    scaffoldBackgroundColor: forceTransparentScaffold ? Colors.transparent : t.surfaceBg,
    cardColor:               t.cardBg,
    dividerColor:            t.divider,
    extensions:              [t],

    // AppBar / Topbar
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor:  t.topbarBg,
      foregroundColor:  t.textPrimary,
      iconTheme:        IconThemeData(color: t.textPrimary, size: 22),
      actionsIconTheme: IconThemeData(color: t.textPrimary, size: 22),
      shadowColor:      t.shadowColor.withValues(alpha: 0.15),
    ),

    // Card
    cardTheme: CardThemeData(
      color:            t.cardBg,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      shadowColor:      t.shadowColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: t.cardBorder),
      ),
    ),

    // DataTable — headers, rows, hover
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(t.tableHeaderBg),
      headingTextStyle: TextStyle(
        color: t.tableHeaderText, fontWeight: FontWeight.w600, fontSize: 12),
      dataTextStyle: TextStyle(color: t.textPrimary, fontSize: 13),
      dataRowColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return t.tableHoverBg;
        if (s.contains(WidgetState.hovered))  return t.tableHoverBg;
        return null;
      }),
      dividerThickness: 1,
      headingRowHeight: 48,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 64,
      columnSpacing: 24,
      horizontalMargin: 20,
    ),

    // Input / TextField
    inputDecorationTheme: InputDecorationTheme(
      filled:             true,
      fillColor:          t.inputBg,
      labelStyle:         TextStyle(color: t.inputLabel),
      hintStyle:          TextStyle(color: t.textHint),
      floatingLabelStyle: TextStyle(color: t.inputFocusBorder),
      prefixIconColor:    t.textHint,
      suffixIconColor:    t.textHint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.inputFocusBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.errorText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: t.errorText, width: 2),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.buttonPrimaryBg,
        foregroundColor: t.buttonPrimaryText,
        minimumSize: const Size(64, 44),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.buttonPrimaryBg,
        foregroundColor: t.buttonPrimaryText,
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.primary,
        side: BorderSide(color: t.primary),
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.primary,
        minimumSize: const Size(64, 44),
      ),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor:     t.chipInactiveBg,
      selectedColor:       t.chipActiveBg,
      labelStyle:          TextStyle(color: t.textPrimary, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: t.chipActiveText),
      side: BorderSide(color: t.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Divider
    dividerTheme: DividerThemeData(color: t.divider, thickness: 1, space: 1),

    // Dialog — heavier glass than cards so form fields are fully readable.
    // Light: 92% blue-50 frosted glass + white rim.
    // Dark:  92% midnight navy glass + subtle blue rim.
    dialogTheme: DialogThemeData(
      backgroundColor: forceTransparentScaffold
          ? (isDark ? const Color(0xEB060D1C) : const Color(0xEBEFF6FF))
          : t.cardBg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: forceTransparentScaffold
            ? BorderSide(
                color: isDark
                    ? const Color(0x331A3860)   // subtle blue rim (dark)
                    : const Color(0xCCFFFFFF),  // white glass rim (light)
                width: 1.5,
              )
            : BorderSide.none,
      ),
      titleTextStyle: TextStyle(
        color: t.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: t.textSecondary, fontSize: 14),
    ),

    // Popup Menu — same heavy glass as dialog
    popupMenuTheme: PopupMenuThemeData(
      color: forceTransparentScaffold
          ? (isDark ? const Color(0xEB060D1C) : const Color(0xEBEFF6FF))
          : t.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: forceTransparentScaffold
            ? BorderSide(
                color: isDark
                    ? const Color(0x331A3860)
                    : const Color(0xCCFFFFFF),
                width: 1,
              )
            : BorderSide(color: t.cardBorder),
      ),
      textStyle: TextStyle(color: t.textPrimary, fontSize: 14),
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      tileColor:         Colors.transparent,
      selectedTileColor: t.navItemActiveBg,
      selectedColor:     t.navItemActiveText,
      iconColor:         t.textSecondary,
      textColor:         t.textPrimary,
    ),

    // Bottom Nav Bar
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor:     t.topbarBg,
      selectedItemColor:   t.primary,
      unselectedItemColor: t.textSecondary,
    ),

    // Navigation Rail
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor:          t.sidebarBg,
      selectedIconTheme:        IconThemeData(color: t.navItemActiveIcon, size: 22),
      unselectedIconTheme:      IconThemeData(color: t.navItemIcon, size: 22),
      selectedLabelTextStyle:   TextStyle(
        color: t.navItemActiveText, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: t.navItemText),
      indicatorColor:           t.navItemActiveBg,
    ),

    // Checkbox
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return t.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(t.onPrimary),
      side: BorderSide(color: t.divider, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return t.onPrimary;
        return t.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return t.primary;
        return t.divider;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    // Tab Bar
    tabBarTheme: TabBarThemeData(
      labelColor:           t.primary,
      unselectedLabelColor: t.textSecondary,
      indicatorColor:       t.primary,
      dividerColor:         t.divider,
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.buttonPrimaryBg,
      foregroundColor: t.buttonPrimaryText,
    ),

    // Progress Indicator
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color:              t.primary,
      linearTrackColor:   t.primary.withValues(alpha: 0.2),
      circularTrackColor: t.primary.withValues(alpha: 0.2),
    ),

    // Text Selection
    textSelectionTheme: TextSelectionThemeData(
      cursorColor:          t.inputFocusBorder,
      selectionColor:       t.inputFocusBorder.withValues(alpha: 0.3),
      selectionHandleColor: t.inputFocusBorder,
    ),

    // Tooltip
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.textPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(color: t.onPrimary, fontSize: 12),
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor:  t.cardBg,
      contentTextStyle: TextStyle(color: t.textPrimary),
      actionTextColor:  t.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class SchoolErpAdminApp extends ConsumerWidget {
  const SchoolErpAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = p.Provider.of<ThemeNotifier>(context);
    final router = ref.watch(routerProvider);
    // Watch live token state — rebuilds MaterialApp whenever a token changes.
    final lightTokens = ref.watch(lightThemeTokensProvider);
    final darkTokens  = ref.watch(darkThemeTokensProvider);

    return MaterialApp.router(
      title: 'Vidyron One — Management Platform',
      debugShowCheckedModeBanner: false,

      // ── SaaS Design System + Dynamic Token Injection ────────────────────────
      // _withTokens injects tokens into both ThemeData.extensions AND the
      // Material 3 colorScheme, so ALL widgets (standard + custom) respond.
      // Light scaffoldBackgroundColor is always transparent so the gradient
      // painted in the builder bleeds through every Scaffold in the route tree.
      theme:     _withTokens(AppTheme.light, lightTokens, forceTransparentScaffold: true),
      darkTheme: _withTokens(AppTheme.dark,  darkTokens,  forceTransparentScaffold: true),
      themeMode: themeNotifier.mode,

      // ── Global Router ──────────────────────────────────────────────────────
      routerConfig: router,

      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final content = AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: InactivityWrapper(child: child ?? const SizedBox()),
        );
        // Both light and dark render the blurred campus background image.
        // Light: subtle white overlay → airy frosted glass panels.
        // Dark:  deep midnight navy overlay (92%) → dark glass panels floating
        //        over a barely-visible campus silhouette.
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: 28,
                sigmaY: 28,
                tileMode: TileMode.decal,
              ),
              child: Image.asset(
                'assets/images/auth_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Dark: heavy midnight overlay — campus barely shows as silhouette.
            // Light: very light white tint so blurred image isn't too bright.
            Container(
              color: isDark
                  ? const Color(0xFF040C18).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            content,
          ],
        );
      },
    );
  }
}
