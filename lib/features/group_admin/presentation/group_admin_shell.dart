// =============================================================================
// FILE: lib/features/group_admin/presentation/group_admin_shell.dart
// PURPOSE: Group Admin layout — web sidebar + TopBar + mobile drawer/bottom nav.
// Glass design system matching super_admin_shell.dart pattern.
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/api_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../widgets/super_admin/notifications_bell_button.dart';
import 'providers/group_admin_profile_provider.dart';

/// Amber accent color for GROUP ADMIN badge
const Color _badgeColor = AppColors.warning300;

class GroupAdminShell extends StatelessWidget {
  const GroupAdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    if (isWide) {
      return _GroupAdminWebLayout(child: child);
    }
    return _GroupAdminMobileLayout(child: child);
  }
}

// =============================================================================
// WEB LAYOUT — sidebar + topbar + content
// =============================================================================

class _GroupAdminWebLayout extends ConsumerStatefulWidget {
  const _GroupAdminWebLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_GroupAdminWebLayout> createState() =>
      _GroupAdminWebLayoutState();
}

class _GroupAdminWebLayoutState extends ConsumerState<_GroupAdminWebLayout> {
  bool _isSidebarCollapsed = false;
  bool _isSidebarHovered = false;

  /// True only when user has pinned collapse AND mouse is not hovering.
  bool get _effectivelyCollapsed => _isSidebarCollapsed && !_isSidebarHovered;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();

    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────
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
                            // Logo + GROUP ADMIN badge
                            InkWell(
                              onTap: () => setState(() =>
                                  _isSidebarCollapsed = !_isSidebarCollapsed),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AppLogoWidget(size: 40, showText: false),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      height: _effectivelyCollapsed ? 0 : 28,
                                      child: _effectivelyCollapsed
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6),
                                              child: AnimatedOpacity(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                opacity:
                                                    _effectivelyCollapsed
                                                        ? 0
                                                        : 1,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _badgeColor
                                                        .withValues(
                                                            alpha: 0.20),
                                                    borderRadius:
                                                        AppRadius.brSm,
                                                    border: Border.all(
                                                      color: _badgeColor
                                                          .withValues(
                                                              alpha: 0.50),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'GROUP ADMIN',
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1.2,
                                                      color:
                                                          AppColors.warning700,
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

                            // Nav items
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                children: [
                                  _NavItem(
                                    icon: Icons.dashboard_outlined,
                                    activeIcon: Icons.dashboard,
                                    label: AppStrings.dashboard,
                                    isActive:
                                        loc.contains('/group-admin/dashboard'),
                                    onTap: () =>
                                        context.go('/group-admin/dashboard'),
                                    isCollapsed: _effectivelyCollapsed,
                                  ),
                                  _NavItem(
                                    icon: Icons.school_outlined,
                                    activeIcon: Icons.school,
                                    label: AppStrings.schools,
                                    isActive:
                                        loc.contains('/group-admin/schools'),
                                    onTap: () =>
                                        context.go('/group-admin/schools'),
                                    isCollapsed: _effectivelyCollapsed,
                                  ),
                                  _NavItem(
                                    icon: Icons.people_outline,
                                    activeIcon: Icons.people,
                                    label: AppStrings.students,
                                    isActive:
                                        loc.contains('/group-admin/students'),
                                    onTap: () =>
                                        context.go('/group-admin/students'),
                                    isCollapsed: _effectivelyCollapsed,
                                  ),

                                  // MANAGEMENT section
                                  _NavGroup(
                                    label: 'MANAGEMENT',
                                    isCollapsed: _effectivelyCollapsed,
                                    children: [
                                      _NavItem(
                                        icon: Icons.analytics_outlined,
                                        activeIcon: Icons.analytics,
                                        label: AppStrings.analytics,
                                        isActive: loc.contains(
                                            '/group-admin/analytics'),
                                        onTap: () => context
                                            .go('/group-admin/analytics'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                      _NavItem(
                                        icon: Icons.bar_chart_outlined,
                                        activeIcon: Icons.bar_chart,
                                        label: AppStrings.reports,
                                        isActive: loc
                                            .contains('/group-admin/reports'),
                                        onTap: () =>
                                            context.go('/group-admin/reports'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                      _NavItem(
                                        icon:
                                            Icons.notifications_active_outlined,
                                        activeIcon: Icons.notifications_active,
                                        label: AppStrings.alerts,
                                        isActive:
                                            loc.contains('/group-admin/alerts'),
                                        onTap: () =>
                                            context.go('/group-admin/alerts'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                      _NavItem(
                                        icon: Icons.campaign_outlined,
                                        activeIcon: Icons.campaign,
                                        label: AppStrings.notices,
                                        isActive: loc
                                            .contains('/group-admin/notices'),
                                        onTap: () =>
                                            context.go('/group-admin/notices'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                    ],
                                  ),

                                  // ACCOUNT section
                                  _NavGroup(
                                    label: 'ACCOUNT',
                                    isCollapsed: _effectivelyCollapsed,
                                    children: [
                                      _NavItem(
                                        icon: Icons.notifications_outlined,
                                        activeIcon: Icons.notifications,
                                        label: AppStrings.notifications,
                                        isActive: loc.contains(
                                            '/group-admin/notifications'),
                                        onTap: () => context
                                            .go('/group-admin/notifications'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                      _NavItem(
                                        icon: Icons.person_outline_rounded,
                                        activeIcon: Icons.person_rounded,
                                        label: AppStrings.profile,
                                        isActive: loc.contains(
                                            '/group-admin/profile'),
                                        onTap: () =>
                                            context.go('/group-admin/profile'),
                                        isCollapsed: _effectivelyCollapsed,
                                      ),
                                      _NavItem(
                                        icon: Icons.lock_reset_outlined,
                                        activeIcon: Icons.lock_reset,
                                        label: AppStrings.changePassword,
                                        isActive: loc.contains(
                                            '/group-admin/change-password'),
                                        onTap: () => context.go(
                                            '/group-admin/change-password'),
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

          // ── Content + Topbar ────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Builder(builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final tokens =
                          Theme.of(context).extension<AppThemeTokens>();
                      return Container(
                        height: 60,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (tokens?.topbarBg ??
                                      const Color(0xFF0A1628))
                                  .withValues(alpha: 0.88)
                              : Colors.white.withValues(alpha: 0.15),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.30),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Spacer(),
                            const ThemeToggleButton(),
                            const SizedBox(width: 8),
                            _GroupAdminLogoutButton(size: 34),
                          ],
                        ),
                      );
                    }),
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

// =============================================================================
// MOBILE LAYOUT — AppBar + Drawer + BottomNav + Content
// =============================================================================

class _GroupAdminMobileLayout extends ConsumerStatefulWidget {
  const _GroupAdminMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_GroupAdminMobileLayout> createState() =>
      _GroupAdminMobileLayoutState();
}

class _GroupAdminMobileLayoutState
    extends ConsumerState<_GroupAdminMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.contains('/group-admin/schools')) {
      _currentIndex = 1;
    } else if (loc.contains('/group-admin/notifications') ||
        loc.contains('/group-admin/profile') ||
        loc.contains('/group-admin/change-password') ||
        loc.contains('/group-admin/analytics') ||
        loc.contains('/group-admin/reports') ||
        loc.contains('/group-admin/notices') ||
        loc.contains('/group-admin/alerts') ||
        loc.contains('/group-admin/students')) {
      _currentIndex = 2; // More (drawer)
    } else {
      _currentIndex = 0; // Dashboard
    }
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'GA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'GA';
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
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeColor.withValues(alpha: 0.20),
                      borderRadius: AppRadius.brXs,
                    ),
                    child: const Text(
                      'GROUP ADMIN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning700,
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
            onPressed: () => context.go('/group-admin/profile'),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: _badgeColor.withValues(alpha: 0.20),
              child: Text(
                _getInitials(
                    ref.watch(authGuardProvider).userEmail ?? 'GA'),
                style: const TextStyle(
                  color: AppColors.warning700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            tooltip: AppStrings.profile,
          ),
        ],
      ),
      drawer: _GroupAdminDrawer(
        isDark: isDark,
        scheme: scheme,
        authEmail: authState.userEmail ?? 'Group Admin',
        getInitials: _getInitials,
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/group-admin/dashboard');
              break;
            case 1:
              context.go('/group-admin/schools');
              break;
            case 2:
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
            icon: Icon(Icons.more_horiz),
            label: AppStrings.more,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// GROUP ADMIN LOGOUT BUTTON (topbar)
// =============================================================================

class _GroupAdminLogoutButton extends ConsumerWidget {
  const _GroupAdminLogoutButton({this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final profileAsync = ref.watch(groupAdminProfileProvider);
    final avatarUrl = _avatarUrl(profileAsync);
    final initials = _getInitials(authState.userEmail ?? 'GA');

    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/group-admin/profile'),
        borderRadius: AppRadius.brXl2,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: Builder(builder: (ctx) {
            final t = Theme.of(ctx).extension<AppThemeTokens>();
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: t?.primary ?? _badgeColor,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      initials,
                      style: TextStyle(
                        color: t?.onPrimary ?? Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: size * 0.38,
                        letterSpacing: 0.5,
                      ),
                    )
                  : null,
            );
          }),
        ),
      ),
    );
  }

  String _avatarUrl(AsyncValue<dynamic> profile) {
    final p = profile.valueOrNull;
    if (p == null) return '';
    final url = p.avatarUrl;
    if (url == null || url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'GA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'GA';
  }
}

// =============================================================================
// MOBILE DRAWER — glass design
// =============================================================================

class _GroupAdminDrawer extends ConsumerWidget {
  const _GroupAdminDrawer({
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

    // Glass colors
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
                // ── Header ──────────────────────────────────────────
                _DrawerHeader(
                  isDark: isDark,
                  scheme: scheme,
                  email: authEmail,
                  initials: getInitials(authEmail),
                ),

                // ── Nav items (scrollable) ──────────────────────────
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [
                      // MAIN section
                      _drawerSectionLabel('MAIN', isDark, scheme),
                      _NavItem(
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        label: AppStrings.dashboard,
                        isActive: isActive('/dashboard'),
                        onTap: () => nav('/group-admin/dashboard'),
                      ),
                      _NavItem(
                        icon: Icons.school_outlined,
                        activeIcon: Icons.school,
                        label: AppStrings.schools,
                        isActive: isActive('/schools'),
                        onTap: () => nav('/group-admin/schools'),
                      ),
                      _NavItem(
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        label: AppStrings.students,
                        isActive: isActive('/students'),
                        onTap: () => nav('/group-admin/students'),
                      ),

                      // MANAGEMENT section
                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel('MANAGEMENT', isDark, scheme),
                      _NavItem(
                        icon: Icons.analytics_outlined,
                        activeIcon: Icons.analytics,
                        label: AppStrings.analytics,
                        isActive: isActive('/analytics'),
                        onTap: () => nav('/group-admin/analytics'),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart,
                        label: AppStrings.reports,
                        isActive: isActive('/reports'),
                        onTap: () => nav('/group-admin/reports'),
                      ),
                      _NavItem(
                        icon: Icons.notifications_active_outlined,
                        activeIcon: Icons.notifications_active,
                        label: AppStrings.alerts,
                        isActive: isActive('/alerts'),
                        onTap: () => nav('/group-admin/alerts'),
                      ),
                      _NavItem(
                        icon: Icons.campaign_outlined,
                        activeIcon: Icons.campaign,
                        label: AppStrings.notices,
                        isActive: isActive('/notices'),
                        onTap: () => nav('/group-admin/notices'),
                      ),

                      // ACCOUNT section
                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel('ACCOUNT', isDark, scheme),
                      _NavItem(
                        icon: Icons.notifications_outlined,
                        activeIcon: Icons.notifications,
                        label: AppStrings.notifications,
                        isActive: isActive('/notifications'),
                        onTap: () => nav('/group-admin/notifications'),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: AppStrings.profile,
                        isActive: isActive('/profile'),
                        onTap: () => nav('/group-admin/profile'),
                      ),
                      _NavItem(
                        icon: Icons.lock_reset_outlined,
                        activeIcon: Icons.lock_reset,
                        label: AppStrings.changePassword,
                        isActive: isActive('/change-password'),
                        onTap: () => nav('/group-admin/change-password'),
                      ),
                    ],
                  ),
                ),

                // ── Logout pinned at bottom ─────────────────────────
                Divider(height: 1, color: divColor),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _NavItem(
                    icon: Icons.logout,
                    activeIcon: Icons.logout,
                    label: AppStrings.signOut,
                    isActive: false,
                    onTap: () => _confirmAndLogout(context, ref),
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

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmGroupAdmin,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).pop(); // close drawer
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/group');
  }
}

// =============================================================================
// DRAWER HEADER — gradient panel + avatar ring + email + role badge
// =============================================================================

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
                  _badgeColor.withValues(alpha: 0.30),
                  _badgeColor.withValues(alpha: 0.10),
                ]
              : [
                  _badgeColor.withValues(alpha: 0.15),
                  _badgeColor.withValues(alpha: 0.04),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : _badgeColor.withValues(alpha: 0.20),
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
                color: _badgeColor.withValues(alpha: 0.50),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: _badgeColor,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
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
              color: _badgeColor,
              borderRadius: AppRadius.brXs,
            ),
            child: const Text(
              'GROUP ADMIN',
              style: TextStyle(
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

// =============================================================================
// NAV GROUP — collapsible section with label + chevron
// =============================================================================

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

    // Use LayoutBuilder so layout adapts to actual rendered width during
    // animation, not the boolean flag (which flips instantly while container
    // still animates).
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
                padding: const EdgeInsets.only(
                    top: 20, bottom: 6, left: 8, right: 4),
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

// =============================================================================
// NAV ITEM — glass-themed with 3px left accent bar on active
// =============================================================================

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
                    child: Tooltip(
                      message: label,
                      child: Icon(
                        isActive ? activeIcon : icon,
                        size: 21,
                        color: isActive ? activeTextColor : inactiveIconColor,
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
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
