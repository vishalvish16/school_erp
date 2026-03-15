// =============================================================================
// FILE: lib/features/super_admin/presentation/super_admin_shell.dart
// PURPOSE: Super Admin layout — web sidebar + TopBar + mobile bottom nav + Drawer
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../widgets/super_admin/logout_button_widget.dart';
import '../../../widgets/super_admin/notifications_bell_button.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

/// Tab indices for Super Admin navigation
enum SuperAdminTab {
  dashboard(0, '/super-admin/dashboard', Icons.dashboard_outlined, Icons.dashboard),
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
  const SuperAdminShell({
    super.key,
    required this.child,
  });

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
  ConsumerState<_SuperAdminWebLayout> createState() => _SuperAdminWebLayoutState();
}

class _SuperAdminWebLayoutState extends ConsumerState<_SuperAdminWebLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          RepaintBoundary(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: _isSidebarCollapsed ? 72 : 214,
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(right: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(_isSidebarCollapsed ? 12 : 20),
                    child: Row(
                      children: [
                        AppLogoWidget(size: 32, showText: !_isSidebarCollapsed),
                        if (!_isSidebarCollapsed) ...[
                          AppSpacing.hGapSm,
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: Text(
                              AppStrings.superAdmin,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                        horizontal: _isSidebarCollapsed ? 8 : 12,
                      ),
                      children: [
                        _NavItem(
                          icon: SuperAdminTab.dashboard.icon,
                          activeIcon: SuperAdminTab.dashboard.activeIcon,
                          label: AppStrings.dashboard,
                          isActive: GoRouterState.of(context).matchedLocation.contains('/dashboard'),
                          onTap: () => context.go('/super-admin/dashboard'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: SuperAdminTab.schools.icon,
                          activeIcon: SuperAdminTab.schools.activeIcon,
                          label: AppStrings.schools,
                          isActive: GoRouterState.of(context).matchedLocation.contains('/schools'),
                          onTap: () => context.go('/super-admin/schools'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.group_outlined,
                          activeIcon: Icons.group,
                          label: AppStrings.groups,
                          isActive: GoRouterState.of(context).matchedLocation.contains('/groups'),
                          onTap: () => context.go('/super-admin/groups'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: SuperAdminTab.plans.icon,
                          activeIcon: SuperAdminTab.plans.activeIcon,
                          label: AppStrings.plans,
                          isActive: GoRouterState.of(context).matchedLocation.contains('/plans'),
                          onTap: () => context.go('/super-admin/plans'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: SuperAdminTab.billing.icon,
                          activeIcon: SuperAdminTab.billing.activeIcon,
                          label: AppStrings.billing,
                          isActive: GoRouterState.of(context).matchedLocation.contains('/billing'),
                          onTap: () => context.go('/super-admin/billing'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        if (!_isSidebarCollapsed) ...[
                          AppSpacing.vGapLg,
                          const Padding(
                            padding: AppSpacing.paddingHMd,
                            child: Text(
                              'MANAGEMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ),
                          AppSpacing.vGapSm,
                        ],
                        _NavItem(
                          icon: Icons.flag_outlined,
                          activeIcon: Icons.flag,
                          label: AppStrings.featureFlags,
                          isActive: loc.contains('/features'),
                          onTap: () => context.go('/super-admin/features'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.devices_outlined,
                          activeIcon: Icons.devices,
                          label: AppStrings.hardware,
                          isActive: loc.contains('/hardware'),
                          onTap: () => context.go('/super-admin/hardware'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.admin_panel_settings_outlined,
                          activeIcon: Icons.admin_panel_settings,
                          label: AppStrings.adminUsers,
                          isActive: loc.contains('/admins'),
                          onTap: () => context.go('/super-admin/admins'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications,
                          label: AppStrings.notifications,
                          isActive: loc.contains('/notifications'),
                          onTap: () => context.go('/super-admin/notifications'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        if (!_isSidebarCollapsed) ...[
                          AppSpacing.vGapLg,
                          const Padding(
                            padding: AppSpacing.paddingHMd,
                            child: Text(
                              'SYSTEM',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ),
                          AppSpacing.vGapSm,
                        ],
                        _NavItem(
                          icon: Icons.history_edu_outlined,
                          activeIcon: Icons.history_edu,
                          label: AppStrings.auditLogs,
                          isActive: loc.contains('/audit-logs'),
                          onTap: () => context.go('/super-admin/audit-logs'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.security_outlined,
                          activeIcon: Icons.security,
                          label: AppStrings.security,
                          isActive: loc.contains('/security'),
                          onTap: () => context.go('/super-admin/security'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.health_and_safety_outlined,
                          activeIcon: Icons.health_and_safety,
                          label: AppStrings.infraStatus,
                          isActive: loc.contains('/infra'),
                          onTap: () => context.go('/super-admin/infra'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: AppStrings.settings,
                          isActive: loc.contains('/settings'),
                          onTap: () => context.go('/super-admin/settings'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.lock_reset_outlined,
                          activeIcon: Icons.lock_reset,
                          label: AppStrings.changePassword,
                          isActive: loc.contains('/change-password'),
                          onTap: () => context.go('/super-admin/change-password'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                        _NavItem(
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: AppStrings.profile,
                          isActive: loc.contains('/profile'),
                          onTap: () => context.go('/super-admin/profile'),
                          isCollapsed: _isSidebarCollapsed,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                      child: Container(
                        height: 56,
                        padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 12 : 20),
                        child: Row(
                          mainAxisAlignment: _isSidebarCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            if (!_isSidebarCollapsed)
                              Text(
                                'Collapse',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            Icon(
                              _isSidebarCollapsed
                                  ? Icons.arrow_forward_ios_rounded
                                  : Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          // Content + minimal top bar (no submenu, no Live)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: AppSpacing.paddingHXl,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      const NotificationsBellButton(),
                      AppSpacing.hGapSm,
                      const ThemeToggleButton(),
                      AppSpacing.hGapSm,
                      _ProfileAvatarButton(size: 32),
                    ],
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

class _SuperAdminMobileLayout extends ConsumerStatefulWidget {
  const _SuperAdminMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_SuperAdminMobileLayout> createState() => _SuperAdminMobileLayoutState();
}

class _SuperAdminMobileLayoutState extends ConsumerState<_SuperAdminMobileLayout> {
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: scheme.primary,
                      child: Text(
                        _getInitials(authState.userEmail ?? 'SA'),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      authState.userEmail ?? 'Super Admin',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: AppRadius.brXs,
                      ),
                      child: Text(
                        AppStrings.superAdmin,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text(AppStrings.dashboard),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text(AppStrings.schools),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/schools');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text(AppStrings.groups),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/groups');
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: const Text(AppStrings.plans),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/plans');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text(AppStrings.billing),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/billing');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text(AppStrings.featureFlags),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/features');
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text(AppStrings.hardware),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/hardware');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text(AppStrings.adminUsers),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/admins');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(AppStrings.notifications),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: const Text(AppStrings.auditLogs),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/audit-logs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text(AppStrings.security),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/security');
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text(AppStrings.infraStatus),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/infra');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text(AppStrings.settings),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text(AppStrings.changePassword),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/change-password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text(AppStrings.profile),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/profile');
              },
            ),
            const Divider(),
            SuperAdminLogoutButton(showLabel: true),
          ],
        ),
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: AppStrings.dashboard),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: AppStrings.schools),
          BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: AppStrings.plans),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: AppStrings.billing),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: AppStrings.more),
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
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authGuardProvider);
    final initials = _getInitials(authState.userEmail ?? 'SA');

    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/super-admin/profile'),
        borderRadius: AppRadius.brXl2,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.4,
              ),
            ),
          ),
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

  static const Color _activeColor = AppColors.info500; // cyan

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            color: isActive ? activeColor.withValues(alpha: 0.10) : null,
            border: isActive
                ? const Border(
                    left: BorderSide(color: _activeColor, width: 2),
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 8 : 12,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: isCollapsed ? 20 : 22,
                  color: isActive ? activeColor : scheme.onSurfaceVariant,
                ),
                if (!isCollapsed) ...[
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? activeColor : scheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (isCollapsed) {
      return Tooltip(message: label, child: content);
    }
    return content;
  }
}
