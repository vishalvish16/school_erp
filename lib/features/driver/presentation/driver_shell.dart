// =============================================================================
// FILE: lib/features/driver/presentation/driver_shell.dart
// PURPOSE: Driver portal layout — mobile-only (BottomNav + glass Drawer).
// Glassmorphism: BackdropFilter glass panels over blurred campus background.
// Accent: orange #FF9800. Badge: DRIVER on dark orange #E65100 bg.
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';

const Color _accentColor = AppColors.driverAccent;
const Color _badgeBgColor = AppColors.driverBadge;

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

const List<_NavEntry> _navItems = [
  _NavEntry(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: AppStrings.dashboard,
    route: '/driver/dashboard',
  ),
  _NavEntry(
    icon: Icons.location_on_outlined,
    activeIcon: Icons.location_on,
    label: AppStrings.driverLiveLocationTitle,
    route: '/driver/live-location',
  ),
  _NavEntry(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: AppStrings.profile,
    route: '/driver/profile',
  ),
];

const List<_NavEntry> _drawerExtraItems = [
  _NavEntry(
    icon: Icons.lock_reset_outlined,
    activeIcon: Icons.lock_reset,
    label: AppStrings.changePassword,
    route: '/driver/change-password',
  ),
];

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _DriverMobileLayout(child: child);
  }
}

// == Mobile Layout (AppBar + BottomNav + glass Drawer) =========================

class _DriverMobileLayout extends ConsumerStatefulWidget {
  const _DriverMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_DriverMobileLayout> createState() =>
      _DriverMobileLayoutState();
}

class _DriverMobileLayoutState extends ConsumerState<_DriverMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.contains('/driver/live-location')) {
      _currentIndex = 1;
    } else if (loc.contains('/driver/profile')) {
      _currentIndex = 2;
    } else {
      _currentIndex = 0;
    }
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
                AppLogoWidget(
                    size: compact ? 24 : AppIconSize.lg, showText: true),
                if (!compact) ...[
                  AppSpacing.hGapSm,
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeBgColor,
                      borderRadius: AppRadius.brXs,
                    ),
                    child: const Text(
                      'DRIVER',
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
            onPressed: () => context.go('/driver/profile'),
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
      drawer: _DriverDrawer(
        isDark: isDark,
        scheme: scheme,
        authEmail: authState.userEmail ?? 'Driver',
        getInitials: _getInitials,
        onLogout: () => _confirmAndLogout(context),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/driver/dashboard');
            case 1:
              context.go('/driver/live-location');
            case 2:
              context.go('/driver/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accentColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: AppStrings.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: AppStrings.driverLiveLocationTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmDriver,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/driver');
  }
}

// == Glass Drawer =============================================================

class _DriverDrawer extends ConsumerWidget {
  const _DriverDrawer({
    required this.isDark,
    required this.scheme,
    required this.authEmail,
    required this.getInitials,
    required this.onLogout,
  });

  final bool isDark;
  final ColorScheme scheme;
  final String authEmail;
  final String Function(String) getInitials;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;

    void nav(String route) {
      Navigator.pop(context);
      context.go(route);
    }

    bool isActive(String route) {
      if (route == '/driver/dashboard') return loc == route;
      return loc.startsWith(route);
    }

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
                // -- Header --
                _DrawerHeader(
                  isDark: isDark,
                  scheme: scheme,
                  email: authEmail,
                  initials: getInitials(authEmail),
                ),

                // -- Nav items (scrollable) --
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      _drawerSectionLabel(AppStrings.main, isDark, scheme),
                      for (final item in _navItems)
                        _NavItem(
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label,
                          isActive: isActive(item.route),
                          onTap: () => nav(item.route),
                        ),

                      const SizedBox(height: 8),
                      Divider(height: 1, color: divColor),
                      _drawerSectionLabel(AppStrings.account, isDark, scheme),
                      for (final item in _drawerExtraItems)
                        _NavItem(
                          icon: item.icon,
                          activeIcon: item.activeIcon,
                          label: item.label,
                          isActive: isActive(item.route),
                          onTap: () => nav(item.route),
                        ),
                    ],
                  ),
                ),

                // -- Logout --
                Divider(height: 1, color: divColor),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _NavItem(
                    icon: Icons.logout,
                    activeIcon: Icons.logout,
                    label: AppStrings.signOut,
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
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
      String label, bool isDark, ColorScheme scheme) {
    return Builder(builder: (ctx) {
      final t = Theme.of(ctx).extension<AppThemeTokens>();
      final c = t?.navItemText.withValues(alpha: 0.6) ??
          (isDark
              ? Colors.white.withValues(alpha: 0.35)
              : scheme.primary.withValues(alpha: 0.55));
      return Padding(
        padding: const EdgeInsets.only(left: 14, top: 14, bottom: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: c,
          ),
        ),
      );
    });
  }
}

// == Drawer Header ============================================================

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
                  _accentColor.withValues(alpha: 0.30),
                  _accentColor.withValues(alpha: 0.10),
                ]
              : [
                  _accentColor.withValues(alpha: 0.12),
                  _accentColor.withValues(alpha: 0.04),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : _accentColor.withValues(alpha: 0.15),
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
                color: _accentColor.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: _accentColor,
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
              color: _badgeBgColor,
              borderRadius: AppRadius.brXs,
            ),
            child: const Text(
              'DRIVER',
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

// == NavItem (AppThemeTokens, 3px active bar) =================================

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final activeTextColor = t?.navItemActiveText ?? Colors.white;
    final inactiveIconColor = t?.navItemIcon ?? const Color(0xFFAEC6E8);
    final inactiveTextColor = t?.navItemText ?? const Color(0xFFAEC6E8);
    final activeBg = t?.navItemActiveBg ?? const Color(0x2E60A5FA);
    final hoverBg = t?.navItemActiveBg.withValues(alpha: 0.5) ??
        const Color(0x1460A5FA);
    final activeAccent = t?.navItemActiveIcon ?? const Color(0xFF60A5FA);
    final borderHint =
        t?.divider.withValues(alpha: 0.3) ??
        Colors.white.withValues(alpha: 0.15);
    final splashHint = activeTextColor.withValues(alpha: 0.1);

    return Material(
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
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 3px active indicator bar
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
          ),
        ),
      ),
    );
  }
}

// == Helpers ==================================================================

String _getInitials(String email) {
  if (email.isEmpty) return 'DR';
  final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'DR';
}
