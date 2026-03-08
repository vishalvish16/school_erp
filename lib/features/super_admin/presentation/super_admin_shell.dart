// =============================================================================
// FILE: lib/features/super_admin/presentation/super_admin_shell.dart
// PURPOSE: Super Admin layout — web sidebar + TopBar + mobile bottom nav + Drawer
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../widgets/super_admin/logout_button_widget.dart';

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
    final isWeb = kIsWeb;
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWeb || isWide) {
      return _SuperAdminWebLayout(child: child);
    }
    return _SuperAdminMobileLayout(child: child);
  }
}

class _SuperAdminWebLayout extends ConsumerWidget {
  const _SuperAdminWebLayout({required this.child});

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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        AppLogoWidget(size: 32, showText: true),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SUPER ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      children: [
                        _NavItem(
                          icon: SuperAdminTab.dashboard.icon,
                          activeIcon: SuperAdminTab.dashboard.activeIcon,
                          label: 'Dashboard',
                          isActive: GoRouterState.of(context).matchedLocation.contains('/dashboard'),
                          onTap: () => context.go('/super-admin/dashboard'),
                        ),
                        _NavItem(
                          icon: SuperAdminTab.schools.icon,
                          activeIcon: SuperAdminTab.schools.activeIcon,
                          label: 'Schools',
                          isActive: GoRouterState.of(context).matchedLocation.contains('/schools'),
                          onTap: () => context.go('/super-admin/schools'),
                        ),
                        _NavItem(
                          icon: Icons.group_outlined,
                          activeIcon: Icons.group,
                          label: 'Groups',
                          isActive: GoRouterState.of(context).matchedLocation.contains('/groups'),
                          onTap: () => context.go('/super-admin/groups'),
                        ),
                        _NavItem(
                          icon: SuperAdminTab.plans.icon,
                          activeIcon: SuperAdminTab.plans.activeIcon,
                          label: 'Plans',
                          isActive: GoRouterState.of(context).matchedLocation.contains('/plans'),
                          onTap: () => context.go('/super-admin/plans'),
                        ),
                        _NavItem(
                          icon: SuperAdminTab.billing.icon,
                          activeIcon: SuperAdminTab.billing.activeIcon,
                          label: 'Billing',
                          isActive: GoRouterState.of(context).matchedLocation.contains('/billing'),
                          onTap: () => context.go('/super-admin/billing'),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'MANAGEMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _NavItem(
                          icon: Icons.flag_outlined,
                          activeIcon: Icons.flag,
                          label: 'Feature Flags',
                          isActive: loc.contains('/features'),
                          onTap: () => context.go('/super-admin/features'),
                        ),
                        _NavItem(
                          icon: Icons.devices_outlined,
                          activeIcon: Icons.devices,
                          label: 'Hardware',
                          isActive: loc.contains('/hardware'),
                          onTap: () => context.go('/super-admin/hardware'),
                        ),
                        _NavItem(
                          icon: Icons.admin_panel_settings_outlined,
                          activeIcon: Icons.admin_panel_settings,
                          label: 'Admin Users',
                          isActive: loc.contains('/admins'),
                          onTap: () => context.go('/super-admin/admins'),
                        ),
                        _NavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications,
                          label: 'Notifications',
                          isActive: loc.contains('/notifications'),
                          onTap: () => context.go('/super-admin/notifications'),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'SYSTEM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _NavItem(
                          icon: Icons.history_edu_outlined,
                          activeIcon: Icons.history_edu,
                          label: 'Audit Logs',
                          isActive: loc.contains('/audit-logs'),
                          onTap: () => context.go('/super-admin/audit-logs'),
                        ),
                        _NavItem(
                          icon: Icons.security_outlined,
                          activeIcon: Icons.security,
                          label: 'Security',
                          isActive: loc.contains('/security'),
                          onTap: () => context.go('/super-admin/security'),
                        ),
                        _NavItem(
                          icon: Icons.health_and_safety_outlined,
                          activeIcon: Icons.health_and_safety,
                          label: 'Infra Status',
                          isActive: loc.contains('/infra'),
                          onTap: () => context.go('/super-admin/infra'),
                        ),
                        _NavItem(
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: 'Settings',
                          isActive: false,
                          onTap: () => context.go('/settings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content + TopBar
          Expanded(
            child: Column(
              children: [
                // TopBar
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => context.go('/super-admin/notifications'),
                        tooltip: 'Notifications',
                      ),
                      SuperAdminLogoutButton(size: 32),
                    ],
                  ),
                ),
                Expanded(child: child),
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
        loc.contains('/infra')) {
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
      appBar: AppBar(
        title: Row(
          children: [
            AppLogoWidget(size: 28, showText: true),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SUPER ADMIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/super-admin/notifications'),
          ),
          SuperAdminLogoutButton(size: 32),
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
                    const SizedBox(height: 12),
                    Text(
                      authState.userEmail ?? 'Super Admin',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUPER ADMIN',
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
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Schools'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/schools');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Groups'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/groups');
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: const Text('Plans'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/plans');
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Billing'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/billing');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Feature Flags'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/features');
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: const Text('Hardware'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/hardware');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Admin Users'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/admins');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: const Text('Audit Logs'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/audit-logs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Security'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/security');
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Infra Status'),
              onTap: () {
                Navigator.pop(context);
                context.go('/super-admin/infra');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
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
              Scaffold.of(context).openDrawer();
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Schools'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: 'Plans'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Billing'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _activeColor = Color(0xFF00D2FF); // cyan

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = scheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive ? activeColor.withValues(alpha: 0.10) : null,
            border: isActive
                ? const Border(
                    left: BorderSide(color: _activeColor, width: 2),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? activeColor : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: isActive ? activeColor : scheme.onSurface,
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
