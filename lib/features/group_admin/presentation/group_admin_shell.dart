// =============================================================================
// FILE: lib/features/group_admin/presentation/group_admin_shell.dart
// PURPOSE: Group Admin layout — web sidebar + TopBar + mobile drawer/bottom nav.
// Copied structure from super_admin_shell.dart; adapted for group admin routes.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/api_config.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import 'providers/group_admin_profile_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../core/constants/app_strings.dart';

/// Top bar tab definition for Group Admin primary navigation
class _TopBarTab {
  const _TopBarTab(this.label, this.route);

  final String label;
  final String route;
}

const List<_TopBarTab> _topBarTabs = [
  _TopBarTab(AppStrings.dashboard, '/group-admin/dashboard'),
  _TopBarTab(AppStrings.schools, '/group-admin/schools'),
  _TopBarTab(AppStrings.students, '/group-admin/students'),
  _TopBarTab(AppStrings.analytics, '/group-admin/analytics'),
  _TopBarTab(AppStrings.reports, '/group-admin/reports'),
  _TopBarTab(AppStrings.notices, '/group-admin/notices'),
  _TopBarTab(AppStrings.alerts, '/group-admin/alerts'),
  _TopBarTab(AppStrings.notifications, '/group-admin/notifications'),
  _TopBarTab(AppStrings.profile, '/group-admin/profile'),
];

/// Amber accent color for GROUP ADMIN badge
const Color _badgeColor = AppColors.warning300;

class GroupAdminShell extends StatelessWidget {
  const GroupAdminShell({
    super.key,
    required this.child,
  });

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

// ── Web Layout ──────────────────────────────────────────────────────────────

class _GroupAdminWebLayout extends ConsumerWidget {
  const _GroupAdminWebLayout({required this.child});

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
                        AppSpacing.hGapSm,
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: _badgeColor.withValues(alpha: 0.20),
                            borderRadius: AppRadius.brSm,
                            border: Border.all(
                                color: _badgeColor.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'GROUP ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning700,
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
                        _NavItem(
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: AppStrings.dashboard,
                          isActive: loc.contains('/group-admin/dashboard'),
                          onTap: () => context.go('/group-admin/dashboard'),
                        ),
                        _NavItem(
                          icon: Icons.school_outlined,
                          activeIcon: Icons.school,
                          label: AppStrings.schools,
                          isActive: loc.contains('/group-admin/schools'),
                          onTap: () => context.go('/group-admin/schools'),
                        ),
                        _NavItem(
                          icon: Icons.people_outline,
                          activeIcon: Icons.people,
                          label: AppStrings.students,
                          isActive: loc.contains('/group-admin/students'),
                          onTap: () => context.go('/group-admin/students'),
                        ),
                        _NavItem(
                          icon: Icons.analytics_outlined,
                          activeIcon: Icons.analytics,
                          label: AppStrings.analytics,
                          isActive: loc.contains('/group-admin/analytics'),
                          onTap: () => context.go('/group-admin/analytics'),
                        ),
                        _NavItem(
                          icon: Icons.bar_chart_outlined,
                          activeIcon: Icons.bar_chart,
                          label: AppStrings.reports,
                          isActive: loc.contains('/group-admin/reports'),
                          onTap: () => context.go('/group-admin/reports'),
                        ),
                        _NavItem(
                          icon: Icons.campaign_outlined,
                          activeIcon: Icons.campaign,
                          label: AppStrings.notices,
                          isActive: loc.contains('/group-admin/notices'),
                          onTap: () => context.go('/group-admin/notices'),
                        ),
                        _NavItem(
                          icon: Icons.notifications_active_outlined,
                          activeIcon: Icons.notifications_active,
                          label: AppStrings.alerts,
                          isActive: loc.contains('/group-admin/alerts'),
                          onTap: () => context.go('/group-admin/alerts'),
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
                        _NavItem(
                          icon: Icons.notifications_outlined,
                          activeIcon: Icons.notifications,
                          label: AppStrings.notifications,
                          isActive: loc.contains('/group-admin/notifications'),
                          onTap: () =>
                              context.go('/group-admin/notifications'),
                        ),
                        _NavItem(
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: AppStrings.profile,
                          isActive: loc == '/group-admin/profile',
                          onTap: () => context.go('/group-admin/profile'),
                        ),
                        _NavItem(
                          icon: Icons.lock_reset_outlined,
                          activeIcon: Icons.lock_reset,
                          label: AppStrings.changePassword,
                          isActive: loc.contains('/group-admin/change-password'),
                          onTap: () =>
                              context.go('/group-admin/change-password'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content area + TopBar
          Expanded(
            child: Column(
              children: [
                // TopBar
                Container(
                  height: 56,
                  padding: AppSpacing.paddingHXl,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < _topBarTabs.length; i++) ...[
                                _TopBarTabButton(
                                  label: _topBarTabs[i].label,
                                  route: _topBarTabs[i].route,
                                  isActive: loc == _topBarTabs[i].route ||
                                      (_topBarTabs[i].route !=
                                              '/group-admin/dashboard' &&
                                          loc.startsWith(
                                              _topBarTabs[i].route)),
                                ),
                                if (i < _topBarTabs.length - 1)
                                  AppSpacing.hGapSm,
                              ],
                            ],
                          ),
                        ),
                      ),
                      AppSpacing.hGapLg,
                      const ThemeToggleButton(),
                      AppSpacing.hGapSm,
                      _GroupAdminLogoutButton(size: 32),
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

// ── Mobile Layout ───────────────────────────────────────────────────────────

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
        loc.contains('/group-admin/reports')) {
      _currentIndex = 2;
    } else {
      _currentIndex = 0;
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
          _GroupAdminLogoutButton(size: 32),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: _badgeColor.withValues(alpha: 0.20),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(
                      builder: (ctx, ref, _) {
                        final profileAsync = ref.watch(groupAdminProfileProvider);
                        final p = profileAsync.valueOrNull;
                        final avatarUrl = (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty)
                            ? (p.avatarUrl!.startsWith('http')
                                ? p.avatarUrl!
                                : '${ApiConfig.baseUrl}${p.avatarUrl}')
                            : '';
                        return CircleAvatar(
                          radius: 32,
                          backgroundColor: _badgeColor,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  _getInitials(authState.userEmail ?? 'GA'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    AppSpacing.vGapMd,
                    Text(
                      authState.userEmail ?? 'Group Admin',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    AppSpacing.vGapXs,
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: _badgeColor,
                        borderRadius: AppRadius.brXs,
                      ),
                      child: const Text(
                        'GROUP ADMIN',
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
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text(AppStrings.dashboard),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text(AppStrings.schools),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/schools');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text(AppStrings.students),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/students');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text(AppStrings.analytics),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/analytics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text(AppStrings.reports),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/reports');
              },
            ),
            ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text(AppStrings.notices),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/notices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text(AppStrings.alerts),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/alerts');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text(AppStrings.notifications),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(AppStrings.profile),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text(AppStrings.changePassword),
              onTap: () {
                Navigator.pop(context);
                context.go('/group-admin/change-password');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(AppStrings.signOut),
              onTap: () async {
                Navigator.pop(context);
                await _confirmAndLogout(context);
              },
            ),
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
              icon: Icon(Icons.dashboard_outlined), label: AppStrings.dashboard),
          BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined), label: AppStrings.schools),
          BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz), label: AppStrings.more),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmGroupAdmin,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/group');
  }
}

// ── Shared Tab Button ───────────────────────────────────────────────────────

class _TopBarTabButton extends StatelessWidget {
  const _TopBarTabButton({
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
          padding: AppSpacing.paddingHMd,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? _badgeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? _badgeColor : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ─────────────────────────────────────────────────────────────────

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
    const activeColor = _badgeColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            color: isActive
                ? activeColor.withValues(alpha: 0.10)
                : null,
            border: isActive
                ? const Border(
                    left: BorderSide(color: activeColor, width: 2),
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
                  color: isActive ? activeColor : scheme.onSurfaceVariant,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
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

// ── Logout Button ─────────────────────────────────────────────────────────────

class _GroupAdminLogoutButton extends ConsumerWidget {
  const _GroupAdminLogoutButton({required this.size});

  final double size;

  String _avatarUrl(AsyncValue<dynamic> profile) {
    final p = profile.valueOrNull;
    if (p == null) return '';
    final url = p.avatarUrl;
    if (url == null || url.isEmpty) return '';
    return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final profileAsync = ref.watch(groupAdminProfileProvider);
    final avatarUrl = _avatarUrl(profileAsync);
    final initials = _getInitials(authState.userEmail ?? 'GA');
    return IconButton(
      onPressed: () => _showLogoutConfirmation(context, ref),
      icon: CircleAvatar(
        radius: size / 2,
        backgroundColor: _badgeColor.withValues(alpha: 0.20),
        backgroundImage: avatarUrl.isNotEmpty
            ? NetworkImage(avatarUrl)
            : null,
        child: avatarUrl.isEmpty
            ? Text(
                initials,
                style: const TextStyle(
                  color: AppColors.warning700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              )
            : null,
      ),
      tooltip: AppStrings.signOut,
    );
  }

  String _getInitials(String email) {
    if (email.isEmpty) return 'GA';
    final parts = email.split('@').first.split(RegExp(r'[.\s]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2 ? email.substring(0, 2).toUpperCase() : 'GA';
  }

  Future<void> _showLogoutConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmGroupAdmin,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/group');
  }
}
