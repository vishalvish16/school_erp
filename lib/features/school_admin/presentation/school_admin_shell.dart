// =============================================================================
// FILE: lib/features/school_admin/presentation/school_admin_shell.dart
// PURPOSE: School Admin layout — web sidebar + TopBar + mobile drawer/bottom nav.
// Accent: green #4CAF50. Badge: SCHOOL ADMIN on dark green #1B5E20 bg.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

const Color _accentColor = AppColors.success500;
const Color _badgeBgColor = AppColors.success700;

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
    route: '/school-admin/dashboard',
  ),
  _NavEntry(
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: AppStrings.students,
    route: '/school-admin/students',
  ),
  _NavEntry(
    icon: Icons.person_search_outlined,
    activeIcon: Icons.person_search,
    label: AppStrings.teachers,
    route: '/school-admin/staff',
  ),
  _NavEntry(
    icon: Icons.class_outlined,
    activeIcon: Icons.class_,
    label: AppStrings.classes,
    route: '/school-admin/classes',
  ),
  _NavEntry(
    icon: Icons.fact_check_outlined,
    activeIcon: Icons.fact_check,
    label: AppStrings.attendance,
    route: '/school-admin/attendance',
  ),
  _NavEntry(
    icon: Icons.payments_outlined,
    activeIcon: Icons.payments,
    label: AppStrings.fees,
    route: '/school-admin/fees',
  ),
  _NavEntry(
    icon: Icons.schedule_outlined,
    activeIcon: Icons.schedule,
    label: AppStrings.timetable,
    route: '/school-admin/timetable',
  ),
  _NavEntry(
    icon: Icons.campaign_outlined,
    activeIcon: Icons.campaign,
    label: AppStrings.notices,
    route: '/school-admin/notices',
  ),
  _NavEntry(
    icon: Icons.badge_outlined,
    activeIcon: Icons.badge,
    label: AppStrings.nonTeachingStaff,
    route: '/school-admin/non-teaching-staff',
  ),
  _NavEntry(
    icon: Icons.how_to_reg_outlined,
    activeIcon: Icons.how_to_reg,
    label: AppStrings.ntAttendance,
    route: '/school-admin/non-teaching-attendance',
  ),
  _NavEntry(
    icon: Icons.event_busy_outlined,
    activeIcon: Icons.event_busy,
    label: AppStrings.ntLeaves,
    route: '/school-admin/non-teaching-leaves',
  ),
];

const List<_NavEntry> _accountItems = [
  _NavEntry(
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    label: AppStrings.notifications,
    route: '/school-admin/notifications',
  ),
  _NavEntry(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: AppStrings.profile,
    route: '/school-admin/profile',
  ),
  _NavEntry(
    icon: Icons.lock_reset_outlined,
    activeIcon: Icons.lock_reset,
    label: AppStrings.changePassword,
    route: '/school-admin/change-password',
  ),
  _NavEntry(
    icon: Icons.manage_accounts_outlined,
    activeIcon: Icons.manage_accounts,
    label: AppStrings.staffRoles,
    route: '/school-admin/non-teaching-roles',
  ),
  _NavEntry(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: AppStrings.settings,
    route: '/school-admin/settings',
  ),
];

// ── Public Shell ─────────────────────────────────────────────────────────────

class SchoolAdminShell extends StatelessWidget {
  const SchoolAdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return isWide
        ? _SchoolAdminWebLayout(child: child)
        : _SchoolAdminMobileLayout(child: child);
  }
}

// ── Web Layout ───────────────────────────────────────────────────────────────

class _SchoolAdminWebLayout extends ConsumerWidget {
  const _SchoolAdminWebLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loc = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 214,
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(right: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo + badge
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        AppLogoWidget(size: 32, showText: true),
                        AppSpacing.hGapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _badgeBgColor,
                            borderRadius: AppRadius.brSm,
                          ),
                          child: const Text(
                            'SCHOOL ADMIN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                      children: [
                        for (final item in _navItems)
                          _NavItem(
                            icon: item.icon,
                            activeIcon: item.activeIcon,
                            label: item.label,
                            isActive: _isActive(loc, item.route),
                            onTap: () => context.go(item.route),
                          ),
                        AppSpacing.vGapLg,
                        const Padding(
                          padding: AppSpacing.paddingHMd,
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral400,
                            ),
                          ),
                        ),
                        AppSpacing.vGapSm,
                        for (final item in _accountItems)
                          _NavItem(
                            icon: item.icon,
                            activeIcon: item.activeIcon,
                            label: item.label,
                            isActive: _isActive(loc, item.route),
                            onTap: () => context.go(item.route),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content area with top bar
          Expanded(
            child: Column(
              children: [
                _SchoolAdminTopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(String loc, String route) {
    if (route == '/school-admin/dashboard') return loc == route;
    return loc.startsWith(route);
  }
}

// ── Top Bar ──────────────────────────────────────────────────────────────────

class _SchoolAdminTopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final loc = GoRouterState.of(context).matchedLocation;
    final allTabs = [..._navItems, ..._accountItems];

    return Container(
      height: 56,
      padding: AppSpacing.paddingHXl,
      decoration: BoxDecoration(
        color: scheme.surface,
        border:
            Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < allTabs.length; i++) ...[
                    _TopTabButton(
                      label: allTabs[i].label,
                      route: allTabs[i].route,
                      isActive: allTabs[i].route == '/school-admin/dashboard'
                          ? loc == allTabs[i].route
                          : loc.startsWith(allTabs[i].route),
                    ),
                    if (i < allTabs.length - 1) AppSpacing.hGapXs,
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.hGapLg,
          const ThemeToggleButton(),
          AppSpacing.hGapSm,
          _SchoolAdminAvatarButton(),
        ],
      ),
    );
  }
}

class _TopTabButton extends StatelessWidget {
  const _TopTabButton({
    required this.label,
    required this.route,
    required this.isActive,
  });

  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: AppRadius.brMd,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? _accentColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? _accentColor : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item (sidebar) ───────────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            color: isActive ? _accentColor.withValues(alpha: 0.10) : null,
            border: isActive
                ? const Border(
                    left: BorderSide(color: _accentColor, width: 2),
                  )
                : null,
          ),
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? _accentColor : scheme.onSurfaceVariant,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? _accentColor : scheme.onSurface,
                    ),
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

// ── Avatar / Logout Button ───────────────────────────────────────────────────

class _SchoolAdminAvatarButton extends ConsumerWidget {
  String _initials(String email) {
    if (email.isEmpty) return 'SA';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'SA';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final initials = _initials(authState.userEmail ?? '');
    return IconButton(
      onPressed: () => _showLogoutDialog(context, ref),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: _accentColor.withValues(alpha: 0.20),
        child: Text(
          initials,
          style: const TextStyle(
            color: _badgeBgColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      tooltip: AppStrings.signOut,
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmSchoolAdmin,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/school');
  }
}

// ── Mobile Layout ────────────────────────────────────────────────────────────

class _SchoolAdminMobileLayout extends ConsumerStatefulWidget {
  const _SchoolAdminMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_SchoolAdminMobileLayout> createState() =>
      _SchoolAdminMobileLayoutState();
}

class _SchoolAdminMobileLayoutState
    extends ConsumerState<_SchoolAdminMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.contains('/school-admin/students')) {
      _currentIndex = 1;
    } else if (loc.contains('/school-admin/fees') ||
        loc.contains('/school-admin/attendance')) {
      _currentIndex = 2;
    } else if (!loc.contains('/school-admin/dashboard')) {
      _currentIndex = 3;
    } else {
      _currentIndex = 0;
    }
  }

  String _initials(String email) {
    if (email.isEmpty) return 'SA';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'SA';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authGuardProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: AppStrings.openMenu,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogoWidget(size: 26, showText: true),
            AppSpacing.hGapSm,
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _badgeBgColor,
                borderRadius: AppRadius.brXs,
              ),
              child: const Text(
                'SCHOOL ADMIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            onPressed: () => _confirmAndLogout(context),
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: _accentColor.withValues(alpha: 0.20),
              child: Text(
                _initials(authState.userEmail ?? ''),
                style: const TextStyle(
                  color: _badgeBgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            tooltip: AppStrings.signOut,
          ),
        ],
      ),
      drawer: _buildDrawer(context, authState),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/school-admin/dashboard');
            case 1:
              context.go('/school-admin/students');
            case 2:
              context.go('/school-admin/fees');
            case 3:
              _scaffoldKey.currentState?.openDrawer();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accentColor,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined), label: AppStrings.dashboard),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline), label: AppStrings.students),
          BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined), label: AppStrings.fees),
          BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz), label: AppStrings.more),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthGuardState authState) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _accentColor,
                    child: Text(
                      _initials(authState.userEmail ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    authState.userEmail ?? 'School Admin',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: _badgeBgColor,
                      borderRadius: AppRadius.brXs,
                    ),
                    child: const Text(
                      'SCHOOL ADMIN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final item in _navItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context);
                context.go(item.route);
              },
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral400,
              ),
            ),
          ),
          for (final item in _accountItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context);
                context.go(item.route);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppStrings.signOut),
            onTap: () async {
              Navigator.pop(context);
              await _confirmAndLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmSchoolAdmin,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/school');
  }
}
