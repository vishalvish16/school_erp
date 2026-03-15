// =============================================================================
// FILE: lib/features/driver/presentation/driver_shell.dart
// PURPOSE: Driver portal layout — mobile-only (BottomNav + Drawer).
// Accent: orange #FF9800. Badge: DRIVER on dark orange #E65100 bg.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../core/constants/app_strings.dart';

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
    if (loc.contains('/driver/profile')) {
      _currentIndex = 1;
    } else {
      _currentIndex = 0;
    }
  }

  String _initials(String email) {
    if (email.isEmpty) return 'DR';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'DR';
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
            AppLogoWidget(size: AppIconSize.lg, showText: true),
            AppSpacing.hGapSm,
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _badgeBgColor,
                borderRadius: AppRadius.brXs,
              ),
              child: Text(
                'DRIVER',
                style: AppTextStyles.caption(color: Colors.white),
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
              backgroundColor: _accentColor.withValues(alpha: AppOpacity.focus),
              child: Text(
                _initials(authState.userEmail ?? ''),
                style: AppTextStyles.caption(color: _badgeBgColor),
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
          if (i == 0) {
            context.go('/driver/dashboard');
          } else {
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
            icon: Icon(Icons.person_outline),
            label: AppStrings.profile,
          ),
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
              color: _accentColor.withValues(alpha: AppOpacity.focus),
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
                      style: AppTextStyles.h5(color: Colors.white),
                    ),
                  ),
                  AppSpacing.vGapMd,
                  Text(
                    authState.userEmail ?? 'Driver',
                    style: AppTextStyles.bodyMd(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.vGapXs,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBgColor,
                      borderRadius: AppRadius.brXs,
                    ),
                    child: Text(
                      'DRIVER',
                      style: AppTextStyles.caption(color: Colors.white),
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
          for (final item in _drawerExtraItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              onTap: () {
                Navigator.pop(context);
                context.go(item.route);
              },
            ),
          AppDivider.horizontal,
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
      message: AppStrings.signOutConfirmDriver,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/driver');
  }
}
