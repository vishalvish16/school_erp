// =============================================================================
// FILE: lib/features/teacher/presentation/teacher_shell.dart
// PURPOSE: Teacher portal layout — web sidebar + TopBar + mobile drawer.
// Glassmorphism: BackdropFilter glass panels matching Super Admin shell.
// Accent: green (success500). Badge: TEACHER on success700 bg.
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';

// ── Nav data ─────────────────────────────────────────────────────────────────

class _NavEntry {
  const _NavEntry({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}

const List<_NavEntry> _mainNavItems = [
  _NavEntry(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: AppStrings.dashboard,
    route: '/teacher/dashboard',
  ),
  _NavEntry(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: AppStrings.attendance,
    route: '/teacher/attendance',
  ),
  _NavEntry(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment,
    label: AppStrings.homework,
    route: '/teacher/homework',
  ),
  _NavEntry(
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book,
    label: AppStrings.classDiary,
    route: '/teacher/diary',
  ),
];

const List<_NavEntry> _accountNavItems = [
  _NavEntry(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: AppStrings.profile,
    route: '/teacher/profile',
  ),
];

// ── Public Shell ─────────────────────────────────────────────────────────────

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return isWide
        ? _TeacherWebLayout(child: child)
        : _TeacherMobileLayout(child: child);
  }
}

// ── Web Layout ───────────────────────────────────────────────────────────────

class _TeacherWebLayout extends ConsumerStatefulWidget {
  const _TeacherWebLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_TeacherWebLayout> createState() => _TeacherWebLayoutState();
}

class _TeacherWebLayoutState extends ConsumerState<_TeacherWebLayout> {
  bool _isSidebarCollapsed = false;
  bool _isSidebarHovered = false;

  bool get _effectivelyCollapsed => _isSidebarCollapsed && !_isSidebarHovered;

  bool _isActive(String loc, String route) {
    if (route == '/teacher/dashboard') return loc == route;
    return loc.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar (glass) ──────────────────────────────────────────────
          RepaintBoundary(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isSidebarHovered = true),
              onExit: (_) => setState(() => _isSidebarHovered = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: _effectivelyCollapsed ? 72 : 214,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? (tokens?.sidebarBg ?? const Color(0xFF0A1628))
                                .withValues(alpha: 0.88)
                            : Colors.white.withValues(alpha: 0.15),
                        border: Border(
                          right: BorderSide(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.30),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        right: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo + badge
                            _LogoBrandArea(
                              isCollapsed: _effectivelyCollapsed,
                              onToggle: () => setState(
                                () => _isSidebarCollapsed = !_isSidebarCollapsed,
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                children: [
                                  for (final item in _mainNavItems)
                                    _NavItem(
                                      icon: item.icon,
                                      activeIcon: item.activeIcon,
                                      label: item.label,
                                      isActive: _isActive(loc, item.route),
                                      onTap: () => context.go(item.route),
                                      isCollapsed: _effectivelyCollapsed,
                                    ),
                                  _NavGroup(
                                    label: AppStrings.account,
                                    isCollapsed: _effectivelyCollapsed,
                                    children: [
                                      for (final item in _accountNavItems)
                                        _NavItem(
                                          icon: item.icon,
                                          activeIcon: item.activeIcon,
                                          label: item.label,
                                          isActive: _isActive(loc, item.route),
                                          onTap: () => context.go(item.route),
                                          isCollapsed: _effectivelyCollapsed,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content + Topbar ──────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _TeacherTopBar(
                  isSidebarCollapsed: _isSidebarCollapsed,
                  onToggleSidebar: () => setState(
                    () => _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo / Brand Area ────────────────────────────────────────────────────────

class _LogoBrandArea extends StatelessWidget {
  const _LogoBrandArea({
    required this.isCollapsed,
    required this.onToggle,
  });

  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppLogoWidget(size: 40, showText: false),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isCollapsed ? 0 : 28,
              child: isCollapsed
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: isCollapsed ? 0 : 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success700,
                            borderRadius: AppRadius.brSm,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            AppStrings.teacherBadge,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar (glass) ──────────────────────────────────────────────────────────

class _TeacherTopBar extends ConsumerWidget {
  const _TeacherTopBar({
    required this.isSidebarCollapsed,
    required this.onToggleSidebar,
  });

  final bool isSidebarCollapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final topbarBg = tokens?.topbarBg ??
        (isDark ? const Color(0xFF0A1628) : Colors.white);
    final borderColor = tokens?.divider ??
        (isDark ? const Color(0x2EFFFFFF) : const Color(0xFFCDD9F0));
    final btnBg = tokens?.navItemActiveBg ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFEEF4FF));
    final btnBorder = tokens?.cardBorder ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFCDD9F0));
    final iconColor = tokens?.textPrimary ??
        (isDark ? Colors.white : const Color(0xFF0F2044));

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? topbarBg.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? borderColor
                    : Colors.white.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Hamburger toggle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: btnBg,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: btnBorder, width: 1),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                      key: ValueKey(isSidebarCollapsed),
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  tooltip: isSidebarCollapsed
                      ? AppStrings.expandSidebar
                      : AppStrings.collapseSidebar,
                  onPressed: onToggleSidebar,
                ),
              ),
              const Spacer(),
              IconTheme(
                data: IconThemeData(color: iconColor, size: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ThemeToggleButton(),
                    AppSpacing.hGapSm,
                    _ProfileAvatarButton(size: 34),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Avatar ───────────────────────────────────────────────────────────

class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final initials = _getInitials(authState.userEmail ?? '');
    final t = Theme.of(context).extension<AppThemeTokens>();

    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/teacher/profile'),
        borderRadius: AppRadius.brXl2,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: t?.primary ?? AppColors.success700,
            child: Text(
              initials,
              style: TextStyle(
                color: t?.onPrimary ?? Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.38,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'TC';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'TC';
  }
}

// ── NavGroup (collapsible section header) ────────────────────────────────────

class _NavGroup extends StatefulWidget {
  const _NavGroup({
    required this.label,
    required this.isCollapsed,
    required this.children,
  });

  final String label;
  final bool isCollapsed;
  final List<Widget> children;

  @override
  State<_NavGroup> createState() => _NavGroupState();
}

class _NavGroupState extends State<_NavGroup> {
  bool _isExpanded = true;

  Widget _buildDivider(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final divColor =
        t?.divider.withValues(alpha: 0.3) ??
        Colors.white.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(indent: 12, endIndent: 12, height: 1, color: divColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final labelColor =
        t?.navItemText.withValues(alpha: 0.6) ??
        Colors.white.withValues(alpha: 0.45);
    final chevronColor =
        t?.navItemIcon.withValues(alpha: 0.6) ??
        Colors.white.withValues(alpha: 0.45);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 100;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildDivider(context), ...widget.children],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: AppRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                  bottom: 6,
                  left: 8,
                  right: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.expand_more,
                        size: 16,
                        color: chevronColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.children,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

// ── Nav Item (AppThemeTokens colors, 3px active bar, collapse-aware) ─────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isCollapsed = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final activeTextColor = t?.navItemActiveText ?? Colors.white;
    final inactiveIconColor = t?.navItemIcon ?? const Color(0xFFAEC6E8);
    final inactiveTextColor = t?.navItemText ?? const Color(0xFFAEC6E8);
    final activeBg = t?.navItemActiveBg ?? const Color(0x2E60A5FA);
    final hoverBg =
        t?.navItemActiveBg.withValues(alpha: 0.5) ??
        const Color(0x1460A5FA);
    final activeAccent = t?.navItemActiveIcon ?? const Color(0xFF60A5FA);
    final borderHint =
        t?.divider.withValues(alpha: 0.3) ??
        Colors.white.withValues(alpha: 0.15);
    final splashHint = activeTextColor.withValues(alpha: 0.1);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        hoverColor: hoverBg,
        splashColor: splashHint,
        highlightColor: splashHint.withValues(alpha: 0.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            color: isActive ? activeBg : Colors.transparent,
            border:
                isActive ? Border.all(color: borderHint, width: 1) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 100;
              if (narrow) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 21,
                      color: isActive ? activeTextColor : inactiveIconColor,
                    ),
                  ),
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color:
                            isActive ? activeAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(
                      isActive ? activeIcon : icon,
                      size: 18,
                      color: isActive ? activeTextColor : inactiveIconColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color:
                              isActive ? activeTextColor : inactiveTextColor,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: label,
        preferBelow: false,
        child: content,
      );
    }
    return content;
  }
}

// ── Mobile Layout ────────────────────────────────────────────────────────────

class _TeacherMobileLayout extends ConsumerStatefulWidget {
  const _TeacherMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_TeacherMobileLayout> createState() =>
      _TeacherMobileLayoutState();
}

class _TeacherMobileLayoutState extends ConsumerState<_TeacherMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/teacher/attendance')) {
      _currentIndex = 1;
    } else if (loc.startsWith('/teacher/homework')) {
      _currentIndex = 2;
    } else if (loc.startsWith('/teacher/diary') ||
        loc.startsWith('/teacher/profile')) {
      _currentIndex = 3;
    } else {
      _currentIndex = 0;
    }
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'TC';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'TC';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authGuardProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: AppStrings.openMenu,
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = MediaQuery.of(context).size.width < 360;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogoWidget(size: compact ? 24 : 28, showText: true),
                if (!compact) ...[
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success700,
                      borderRadius: AppRadius.brXs,
                    ),
                    child: const Text(
                      AppStrings.teacherBadge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            onPressed: () => context.go('/teacher/profile'),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                _getInitials(authState.userEmail ?? ''),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            tooltip: AppStrings.profile,
          ),
        ],
      ),
      drawer: _TeacherDrawer(
        isDark: isDark,
        scheme: scheme,
        authEmail: authState.userEmail ?? AppStrings.teacherLabel,
        getInitials: _getInitials,
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/teacher/dashboard');
            case 1:
              context.go('/teacher/attendance');
            case 2:
              context.go('/teacher/homework');
            case 3:
              _scaffoldKey.currentState?.openDrawer();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            label: AppStrings.attendance,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: AppStrings.homework,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: AppStrings.more,
          ),
        ],
      ),
    );
  }
}

// ── Mobile Drawer (glass) ────────────────────────────────────────────────────

class _TeacherDrawer extends ConsumerWidget {
  const _TeacherDrawer({
    required this.isDark,
    required this.scheme,
    required this.authEmail,
    required this.getInitials,
  });

  final bool isDark;
  final ColorScheme scheme;
  final String authEmail;
  final String Function(String) getInitials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;

    void nav(String route) {
      Navigator.pop(context);
      context.go(route);
    }

    bool isActive(String segment) => loc.contains(segment);

    final bgColor = isDark
        ? const Color(0xFF0A1628).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.88);

    final divColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : scheme.primary.withValues(alpha: 0.12);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            color: bgColor,
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _DrawerHeader(
                  isDark: isDark,
                  scheme: scheme,
                  email: authEmail,
                  initials: getInitials(authEmail),
                  badgeLabel: AppStrings.teacherBadge,
                  badgeColor: AppColors.success700,
                ),

                // ── Nav items (scrollable) ────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      _drawerSectionLabel(AppStrings.main, isDark, scheme),
                      for (final item in _mainNavItems)
                        _NavItem(
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label,
                          isActive: isActive(
                            item.route.replaceFirst('/teacher/', '/'),
                          ),
                          onTap: () => nav(item.route),
                        ),

                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel(
                        AppStrings.account,
                        isDark,
                        scheme,
                      ),
                      for (final item in _accountNavItems)
                        _NavItem(
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label,
                          isActive: isActive(
                            item.route.replaceFirst('/teacher/', '/'),
                          ),
                          onTap: () => nav(item.route),
                        ),
                    ],
                  ),
                ),

                // ── Logout ────────────────────────────────────────────────
                Divider(height: 1, color: divColor),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _NavItem(
                    icon: Icons.logout,
                    activeIcon: Icons.logout,
                    label: AppStrings.signOut,
                    isActive: false,
                    onTap: () async {
                      final confirmed = await AppDialogs.confirm(
                        context,
                        title: AppStrings.signOutQuestion,
                        message: AppStrings.signOutConfirmTeacher,
                        confirmLabel: AppStrings.signOut,
                      );
                      if (!confirmed || !context.mounted) return;
                      Navigator.of(context).pop(); // close drawer
                      await ref
                          .read(authGuardProvider.notifier)
                          .clearSession();
                      if (context.mounted) context.go('/login/teacher');
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(
    String label,
    bool isDark,
    ColorScheme scheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 14, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : scheme.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// ── Drawer Header ────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isDark,
    required this.scheme,
    required this.email,
    required this.initials,
    required this.badgeLabel,
    required this.badgeColor,
  });

  final bool isDark;
  final ColorScheme scheme;
  final String email;
  final String initials;
  final String badgeLabel;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scheme.primary.withValues(alpha: 0.30),
                  scheme.primary.withValues(alpha: 0.10),
                ]
              : [
                  scheme.primary.withValues(alpha: 0.12),
                  scheme.primary.withValues(alpha: 0.04),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : scheme.primary.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primary,
              child: Text(
                initials,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
