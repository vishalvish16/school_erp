// =============================================================================
// FILE: lib/features/super_admin/presentation/super_admin_shell.dart
// PURPOSE: Super Admin layout — web sidebar + TopBar + mobile bottom nav + Drawer
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../widgets/super_admin/logout_button_widget.dart';
import '../../../widgets/super_admin/notifications_bell_button.dart';

/// Tab indices for Super Admin navigation
enum SuperAdminTab {
  dashboard(
    0,
    '/super-admin/dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
  ),
  schools(1, '/super-admin/schools', Icons.school_outlined, Icons.school),
  plans(2, '/super-admin/plans', Icons.layers_outlined, Icons.layers),
  billing(3, '/super-admin/billing', Icons.payments_outlined, Icons.payments),
  more(4, '', Icons.more_horiz, Icons.more_horiz);

  const SuperAdminTab(this.tabIndex, this.route, this.icon, this.activeIcon);
  final int tabIndex;
  final String route;
  final IconData icon;
  final IconData activeIcon;
}

class SuperAdminShell extends StatelessWidget {
  const SuperAdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Use screen width for layout: mobile (drawer) on narrow, web (sidebar) on wide.
    // This ensures mobile layout on web when viewport is narrow (e.g. responsive testing).
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWide) {
      return _SuperAdminWebLayout(child: child);
    }
    return _SuperAdminMobileLayout(child: child);
  }
}

class _SuperAdminWebLayout extends ConsumerStatefulWidget {
  const _SuperAdminWebLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_SuperAdminWebLayout> createState() =>
      _SuperAdminWebLayoutState();
}

class _SuperAdminWebLayoutState extends ConsumerState<_SuperAdminWebLayout> {
  bool _isSidebarCollapsed = false;
  bool _isSidebarHovered = false;

  /// True only when user has pinned collapse AND mouse is not hovering.
  bool get _effectivelyCollapsed => _isSidebarCollapsed && !_isSidebarHovered;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          RepaintBoundary(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isSidebarHovered = true),
              onExit: (_) => setState(() => _isSidebarHovered = false),
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: _effectivelyCollapsed ? 72 : 214,
              decoration: isDark
                  ? null
                  : BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withAlpha(14),
                          blurRadius: 8,
                          offset: const Offset(4, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 1,
                          offset: const Offset(1, 0),
                        ),
                      ],
                    ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                      border: Border(
                        right: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.lightBorder,
                          width: 1,
                        ),
                      ),
                    ),
              child: SafeArea(
                right: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Branding section
                    InkWell(
                      onTap: () => setState(
                          () => _isSidebarCollapsed = !_isSidebarCollapsed),
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
                              height: _effectivelyCollapsed ? 0 : 28,
                              child: _effectivelyCollapsed
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: AnimatedOpacity(
                                        duration: const Duration(milliseconds: 150),
                                        opacity: _effectivelyCollapsed ? 0 : 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: AppRadius.brSm,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            AppStrings.superAdmin.toUpperCase(),
                                            style: const TextStyle(
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
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        children: [
                          _NavItem(
                            icon: SuperAdminTab.dashboard.icon,
                            activeIcon: SuperAdminTab.dashboard.activeIcon,
                            label: AppStrings.dashboard,
                            isActive: loc.contains('/dashboard'),
                            onTap: () => context.go('/super-admin/dashboard'),
                            isCollapsed: _effectivelyCollapsed,
                          ),
                          _NavItem(
                            icon: SuperAdminTab.schools.icon,
                            activeIcon: SuperAdminTab.schools.activeIcon,
                            label: AppStrings.schools,
                            isActive: loc.contains('/schools'),
                            onTap: () => context.go('/super-admin/schools'),
                            isCollapsed: _effectivelyCollapsed,
                          ),
                          _NavItem(
                            icon: Icons.group_outlined,
                            activeIcon: Icons.group,
                            label: AppStrings.groups,
                            isActive: loc.contains('/groups'),
                            onTap: () => context.go('/super-admin/groups'),
                            isCollapsed: _effectivelyCollapsed,
                          ),
                          _NavItem(
                            icon: SuperAdminTab.plans.icon,
                            activeIcon: SuperAdminTab.plans.activeIcon,
                            label: AppStrings.plans,
                            isActive: loc.contains('/plans'),
                            onTap: () => context.go('/super-admin/plans'),
                            isCollapsed: _effectivelyCollapsed,
                          ),
                          _NavItem(
                            icon: SuperAdminTab.billing.icon,
                            activeIcon: SuperAdminTab.billing.activeIcon,
                            label: AppStrings.billing,
                            isActive: loc.contains('/billing'),
                            onTap: () => context.go('/super-admin/billing'),
                            isCollapsed: _effectivelyCollapsed,
                          ),
                          _NavGroup(
                            label: 'MANAGEMENT',
                            isCollapsed: _effectivelyCollapsed,
                            children: [
                              _NavItem(
                                icon: Icons.flag_outlined,
                                activeIcon: Icons.flag,
                                label: AppStrings.featureFlags,
                                isActive: loc.contains('/features'),
                                onTap: () => context.go('/super-admin/features'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.devices_outlined,
                                activeIcon: Icons.devices,
                                label: AppStrings.hardware,
                                isActive: loc.contains('/hardware'),
                                onTap: () => context.go('/super-admin/hardware'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.admin_panel_settings_outlined,
                                activeIcon: Icons.admin_panel_settings,
                                label: AppStrings.adminUsers,
                                isActive: loc.contains('/admins'),
                                onTap: () => context.go('/super-admin/admins'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.notifications_outlined,
                                activeIcon: Icons.notifications,
                                label: AppStrings.notifications,
                                isActive: loc.contains('/notifications'),
                                onTap: () => context.go('/super-admin/notifications'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                            ],
                          ),
                          _NavGroup(
                            label: 'SYSTEM',
                            isCollapsed: _effectivelyCollapsed,
                            children: [
                              _NavItem(
                                icon: Icons.history_edu_outlined,
                                activeIcon: Icons.history_edu,
                                label: AppStrings.auditLogs,
                                isActive: loc.contains('/audit-logs'),
                                onTap: () => context.go('/super-admin/audit-logs'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.security_outlined,
                                activeIcon: Icons.security,
                                label: AppStrings.security,
                                isActive: loc.contains('/security'),
                                onTap: () => context.go('/super-admin/security'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.health_and_safety_outlined,
                                activeIcon: Icons.health_and_safety,
                                label: AppStrings.infraStatus,
                                isActive: loc.contains('/infra'),
                                onTap: () => context.go('/super-admin/infra'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.palette_outlined,
                                activeIcon: Icons.palette,
                                label: 'Theme',
                                isActive: loc.contains('/theme'),
                                onTap: () => context.go('/super-admin/theme'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.settings_outlined,
                                activeIcon: Icons.settings,
                                label: AppStrings.settings,
                                isActive: loc.contains('/settings'),
                                onTap: () => context.go('/super-admin/settings'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.lock_reset_outlined,
                                activeIcon: Icons.lock_reset,
                                label: AppStrings.changePassword,
                                isActive: loc.contains('/change-password'),
                                onTap: () => context.go('/super-admin/change-password'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                              _NavItem(
                                icon: Icons.person_outline_rounded,
                                activeIcon: Icons.person_rounded,
                                label: AppStrings.profile,
                                isActive: loc.contains('/profile'),
                                onTap: () => context.go('/super-admin/profile'),
                                isCollapsed: _effectivelyCollapsed,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Builder(builder: (ctx) {
                      final t = Theme.of(ctx).extension<AppThemeTokens>();
                      final divColor = t?.divider.withValues(alpha: 0.3) ??
                          Colors.white.withValues(alpha: 0.15);
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Divider(height: 1, color: divColor),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                            child: _SidebarSignOutButton(
                              isCollapsed: _effectivelyCollapsed,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ],
                ),
              ),            // closes SafeArea
                  ),        // closes Container (glass decoration)
                ),          // closes BackdropFilter
              ),            // closes ClipRect
            ),              // closes AnimatedContainer
          ),                // closes MouseRegion
          ),                // closes RepaintBoundary
          // Content + minimal top bar (no submenu, no Live)
          Expanded(
            child: Column(
              children: [
                Builder(builder: (context) {
                  final tokens = Theme.of(context).extension<AppThemeTokens>();
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final topbarBg    = tokens?.topbarBg    ?? (isDark ? const Color(0xFF0A1628) : Colors.white);
                  final borderColor = tokens?.divider     ?? (isDark ? const Color(0x2EFFFFFF) : const Color(0xFFCDD9F0));
                  final btnBg       = tokens?.navItemActiveBg ?? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEEF4FF));
                  final btnBorder   = tokens?.cardBorder  ?? (isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFCDD9F0));
                  final iconColor   = tokens?.textPrimary ?? (isDark ? Colors.white : const Color(0xFF0F2044));
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
                              : Colors.white.withValues(alpha: 0.3),
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
                                _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                                key: ValueKey(_isSidebarCollapsed),
                                size: 18,
                                color: iconColor,
                              ),
                            ),
                            tooltip: _isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                            onPressed: () => setState(
                              () => _isSidebarCollapsed = !_isSidebarCollapsed,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // All topbar icons inherit the same color
                        IconTheme(
                          data: IconThemeData(color: iconColor, size: 22),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const NotificationsBellButton(),
                              AppSpacing.hGapXs,
                              const ThemeToggleButton(),
                              AppSpacing.hGapSm,
                              const _SignOutIconButton(),
                              AppSpacing.hGapXs,
                              _ProfileAvatarButton(size: 34),
                            ],
                          ),
                        ),
                      ],
                    ),
                      ),     // closes Container
                    ),       // closes BackdropFilter
                  );         // closes ClipRect
                }),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuperAdminMobileLayout extends ConsumerStatefulWidget {
  const _SuperAdminMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_SuperAdminMobileLayout> createState() =>
      _SuperAdminMobileLayoutState();
}

class _SuperAdminMobileLayoutState
    extends ConsumerState<_SuperAdminMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.contains('/schools')) {
      _currentIndex = 1;
    } else if (loc.contains('/plans')) {
      _currentIndex = 2;
    } else if (loc.contains('/billing')) {
      _currentIndex = 3;
    } else if (loc.contains('/groups') ||
        loc.contains('/features') ||
        loc.contains('/hardware') ||
        loc.contains('/admins') ||
        loc.contains('/notifications') ||
        loc.contains('/audit-logs') ||
        loc.contains('/security') ||
        loc.contains('/infra') ||
        loc.contains('/settings') ||
        loc.contains('/profile')) {
      _currentIndex = 4; // More (drawer)
    } else {
      _currentIndex = 0; // Dashboard
    }
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'SA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'SA';
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
          tooltip: 'Open menu',
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
                      color: scheme.primaryContainer,
                      borderRadius: AppRadius.brXs,
                    ),
                    child: Text(
                      AppStrings.superAdmin,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
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
          const NotificationsBellButton(),
          IconButton(
            onPressed: () => context.go('/super-admin/profile'),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                _getInitials(ref.watch(authGuardProvider).userEmail ?? 'SA'),
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
      drawer: _SuperAdminDrawer(
        isDark: isDark,
        scheme: scheme,
        authEmail: authState.userEmail ?? 'Super Admin',
        getInitials: _getInitials,
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/super-admin/dashboard');
              break;
            case 1:
              context.go('/super-admin/schools');
              break;
            case 2:
              context.go('/super-admin/plans');
              break;
            case 3:
              context.go('/super-admin/billing');
              break;
            case 4:
              _scaffoldKey.currentState?.openDrawer();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: AppStrings.schools,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers_outlined),
            label: AppStrings.plans,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: AppStrings.billing,
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

class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final initials = _getInitials(authState.userEmail ?? 'SA');

    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/super-admin/profile'),
        borderRadius: AppRadius.brXl2,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: Builder(builder: (ctx) {
            final t = Theme.of(ctx).extension<AppThemeTokens>();
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: t?.primary ?? const Color(0xFF0F2044),
              child: Text(
                initials,
                style: TextStyle(
                  color: t?.onPrimary ?? Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.38,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'SA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'SA';
  }
}

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
    final divColor = t?.divider.withValues(alpha: 0.3) ?? Colors.white.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(indent: 12, endIndent: 12, height: 1, color: divColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final labelColor  = t?.navItemText.withValues(alpha: 0.6)  ?? Colors.white.withValues(alpha: 0.45);
    final chevronColor = t?.navItemIcon.withValues(alpha: 0.6) ?? Colors.white.withValues(alpha: 0.45);

    // Use LayoutBuilder so layout adapts to actual rendered width during animation,
    // not the boolean flag (which flips instantly while container still animates).
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 100;

        if (narrow) {
          // Icon-only mode: divider separator, children always visible
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_buildDivider(context), ...widget.children],
          );
        }

        // Full-width mode: clickable header with chevron + animated children
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: AppRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 6, left: 8, right: 4),
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
    final activeTextColor   = t?.navItemActiveText ?? Colors.white;
    final inactiveIconColor = t?.navItemIcon       ?? const Color(0xFFAEC6E8);
    final inactiveTextColor = t?.navItemText       ?? const Color(0xFFAEC6E8);
    final activeBg          = t?.navItemActiveBg   ?? const Color(0x2E60A5FA);
    final hoverBg           = t?.navItemActiveBg.withValues(alpha: 0.5) ?? const Color(0x1460A5FA);
    final activeAccent      = t?.navItemActiveIcon ?? const Color(0xFF60A5FA);
    final borderHint        = t?.divider.withValues(alpha: 0.3) ?? Colors.white.withValues(alpha: 0.15);
    final splashHint        = activeTextColor.withValues(alpha: 0.1);

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
            border: isActive ? Border.all(color: borderHint, width: 1) : null,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isActive ? activeAccent : Colors.transparent,
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
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? activeTextColor : inactiveTextColor,
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

// ─── Mobile Drawer ────────────────────────────────────────────────────────────

class _SuperAdminDrawer extends ConsumerWidget {
  const _SuperAdminDrawer({
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

    // Light mode: 88% white so text is crisp and the campus image tints through.
    // Dark mode: deep navy 94%.
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
                // ── Header ────────────────────────────────────────────────────
                _DrawerHeader(
                  isDark: isDark,
                  scheme: scheme,
                  email: authEmail,
                  initials: getInitials(authEmail),
                ),

                // ── Nav items (scrollable) ─────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      // Primary section
                      _drawerSectionLabel('MAIN', isDark, scheme),
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: AppStrings.dashboard,
                        isActive: isActive('/dashboard'),
                        onTap: () => nav('/super-admin/dashboard'),
                      ),
                      _NavItem(
                        icon: Icons.school_outlined,
                        activeIcon: Icons.school,
                        label: AppStrings.schools,
                        isActive: isActive('/schools'),
                        onTap: () => nav('/super-admin/schools'),
                      ),
                      _NavItem(
                        icon: Icons.group_outlined,
                        activeIcon: Icons.group,
                        label: AppStrings.groups,
                        isActive: isActive('/groups'),
                        onTap: () => nav('/super-admin/groups'),
                      ),
                      _NavItem(
                        icon: Icons.layers_outlined,
                        activeIcon: Icons.layers,
                        label: AppStrings.plans,
                        isActive: isActive('/plans'),
                        onTap: () => nav('/super-admin/plans'),
                      ),
                      _NavItem(
                        icon: Icons.payments_outlined,
                        activeIcon: Icons.payments,
                        label: AppStrings.billing,
                        isActive: isActive('/billing'),
                        onTap: () => nav('/super-admin/billing'),
                      ),

                      // System section
                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel('SYSTEM', isDark, scheme),
                      _NavItem(
                        icon: Icons.flag_outlined,
                        activeIcon: Icons.flag,
                        label: AppStrings.featureFlags,
                        isActive: isActive('/features'),
                        onTap: () => nav('/super-admin/features'),
                      ),
                      _NavItem(
                        icon: Icons.devices_outlined,
                        activeIcon: Icons.devices,
                        label: AppStrings.hardware,
                        isActive: isActive('/hardware'),
                        onTap: () => nav('/super-admin/hardware'),
                      ),
                      _NavItem(
                        icon: Icons.admin_panel_settings_outlined,
                        activeIcon: Icons.admin_panel_settings,
                        label: AppStrings.adminUsers,
                        isActive: isActive('/admins'),
                        onTap: () => nav('/super-admin/admins'),
                      ),
                      _NavItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: AppStrings.notifications,
                        isActive: isActive('/notifications'),
                        onTap: () => nav('/super-admin/notifications'),
                      ),
                      _NavItem(
                        icon: Icons.history_edu_outlined,
                        activeIcon: Icons.history_edu,
                        label: AppStrings.auditLogs,
                        isActive: isActive('/audit-logs'),
                        onTap: () => nav('/super-admin/audit-logs'),
                      ),
                      _NavItem(
                        icon: Icons.security_outlined,
                        activeIcon: Icons.security,
                        label: AppStrings.security,
                        isActive: isActive('/security'),
                        onTap: () => nav('/super-admin/security'),
                      ),
                      _NavItem(
                        icon: Icons.health_and_safety_outlined,
                        activeIcon: Icons.health_and_safety,
                        label: AppStrings.infraStatus,
                        isActive: isActive('/infra'),
                        onTap: () => nav('/super-admin/infra'),
                      ),

                      // Account section
                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel('ACCOUNT', isDark, scheme),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person,
                        label: AppStrings.profile,
                        isActive: isActive('/profile'),
                        onTap: () => nav('/super-admin/profile'),
                      ),
                      _NavItem(
                        icon: Icons.lock_reset_outlined,
                        activeIcon: Icons.lock_reset,
                        label: AppStrings.changePassword,
                        isActive: isActive('/change-password'),
                        onTap: () => nav('/super-admin/change-password'),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: AppStrings.settings,
                        isActive: isActive('/settings'),
                        onTap: () => nav('/super-admin/settings'),
                      ),
                    ],
                  ),
                ),

                // ── Logout ────────────────────────────────────────────────────
                Divider(height: 1, color: divColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: SuperAdminLogoutButton(showLabel: true),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(String label, bool isDark, ColorScheme scheme) {
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isDark,
    required this.scheme,
    required this.email,
    required this.initials,
  });

  final bool isDark;
  final ColorScheme scheme;
  final String email;
  final String initials;

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
              color: scheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SUPER ADMIN',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sign-Out: Topbar icon ────────────────────────────────────────────────────

class _SignOutIconButton extends ConsumerWidget {
  const _SignOutIconButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Sign Out',
      child: InkWell(
        onTap: () => _confirm(context, ref),
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: Icon(Icons.logout_rounded, color: scheme.error, size: 20),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Sign Out?',
      message: 'You will be logged out of the Super Admin portal.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    await SuperAdminLogoutButton.performLogout(context, ref);
  }
}

// ─── Sign-Out: Sidebar bottom button ─────────────────────────────────────────

class _SidebarSignOutButton extends ConsumerWidget {
  const _SidebarSignOutButton({required this.isCollapsed});

  final bool isCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorColor = Theme.of(context).colorScheme.error;

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _confirm(context, ref),
        borderRadius: AppRadius.brMd,
        hoverColor: errorColor.withValues(alpha: 0.08),
        splashColor: errorColor.withValues(alpha: 0.12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 100;
            if (narrow) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Center(
                  child: Icon(Icons.logout_rounded, size: 21, color: errorColor),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 13),
                  Icon(Icons.logout_rounded, size: 18, color: errorColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: errorColor,
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
    );

    if (isCollapsed) {
      return Tooltip(message: 'Sign Out', preferBelow: false, child: content);
    }
    return content;
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Sign Out?',
      message: 'You will be logged out of the Super Admin portal.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;
    await SuperAdminLogoutButton.performLogout(context, ref);
  }
}
