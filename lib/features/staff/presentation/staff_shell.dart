// =============================================================================
// FILE: lib/features/staff/presentation/staff_shell.dart
// PURPOSE: Staff/Clerk portal layout -- glassmorphism sidebar + TopBar + mobile drawer.
// Accent: blue. Badge: STAFF on dark blue bg.
// =============================================================================

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme_tokens.dart';
import '../../../design_system/design_system.dart';
import '../../../features/auth/auth_guard_provider.dart';
import '../../../widgets/super_admin/notifications_bell_button.dart';
import '../../school_admin/presentation/providers/profile_requests_provider.dart';

const Color _accentColor = AppColors.secondary400;
const Color _badgeBgColor = AppColors.secondary900;

// ── Nav entry model ─────────────────────────────────────────────────────────

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
    route: '/staff/dashboard',
  ),
  _NavEntry(
    icon: Icons.payments_outlined,
    activeIcon: Icons.payments,
    label: AppStrings.feeCollection,
    route: '/staff/fees',
  ),
  _NavEntry(
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: AppStrings.students,
    route: '/staff/students',
  ),
  _NavEntry(
    icon: Icons.campaign_outlined,
    activeIcon: Icons.campaign,
    label: AppStrings.notices,
    route: '/staff/notices',
  ),
  _NavEntry(
    icon: Icons.event_note_outlined,
    activeIcon: Icons.event_note,
    label: AppStrings.myAttendance,
    route: '/staff/my-attendance',
  ),
  _NavEntry(
    icon: Icons.beach_access_outlined,
    activeIcon: Icons.beach_access,
    label: AppStrings.myLeaves,
    route: '/staff/my-leaves',
  ),
  _NavEntry(
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long,
    label: AppStrings.payslip,
    route: '/staff/payslip',
  ),
  _NavEntry(
    icon: Icons.manage_accounts_outlined,
    activeIcon: Icons.manage_accounts,
    label: AppStrings.profileRequests,
    route: '/staff/profile-requests',
  ),
];

const List<_NavEntry> _accountItems = [
  _NavEntry(
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications,
    label: AppStrings.notifications,
    route: '/staff/notifications',
  ),
  _NavEntry(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: AppStrings.profile,
    route: '/staff/profile',
  ),
  _NavEntry(
    icon: Icons.lock_reset_outlined,
    activeIcon: Icons.lock_reset,
    label: AppStrings.changePassword,
    route: '/staff/change-password',
  ),
];

// ── Public Shell ─────────────────────────────────────────────────────────────

class StaffShell extends StatelessWidget {
  const StaffShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    return isWide
        ? _StaffWebLayout(child: child)
        : _StaffMobileLayout(child: child);
  }
}

// ── Web Layout ───────────────────────────────────────────────────────────────

class _StaffWebLayout extends ConsumerStatefulWidget {
  const _StaffWebLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_StaffWebLayout> createState() => _StaffWebLayoutState();
}

class _StaffWebLayoutState extends ConsumerState<_StaffWebLayout> {
  bool _isSidebarCollapsed = false;
  bool _isSidebarHovered = false;

  bool get _effectivelyCollapsed =>
      _isSidebarCollapsed && !_isSidebarHovered;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // ── Glass Sidebar ──────────────────────────────────────────
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
                            ? (tokens?.sidebarBg ??
                                    const Color(0xFF0A1628))
                                .withValues(alpha: 0.88)
                            : AppColors.lightSurface,
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
                            // Logo + badge
                            InkWell(
                              onTap: () => setState(() =>
                                  _isSidebarCollapsed =
                                      !_isSidebarCollapsed),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    AppLogoWidget(
                                        size: 40, showText: false),
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 150),
                                      height: _effectivelyCollapsed
                                          ? 0
                                          : 28,
                                      child: _effectivelyCollapsed
                                          ? const SizedBox.shrink()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 6),
                                              child: AnimatedOpacity(
                                                duration: const Duration(
                                                    milliseconds: 150),
                                                opacity:
                                                    _effectivelyCollapsed
                                                        ? 0
                                                        : 1,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 10,
                                                    vertical: 3,
                                                  ),
                                                  decoration:
                                                      BoxDecoration(
                                                    color: _badgeBgColor,
                                                    borderRadius:
                                                        AppRadius.brSm,
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha:
                                                                  0.25),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    AppStrings.staffBadge,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
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

                            // Nav items
                            Expanded(
                              child: _StaffSidebarNavList(
                                loc: loc,
                                isCollapsed: _effectivelyCollapsed,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: _NavItem(
                                icon: Icons.logout,
                                activeIcon: Icons.logout,
                                label: AppStrings.signOut,
                                isActive: false,
                                isCollapsed: _effectivelyCollapsed,
                                onTap: () => _confirmAndLogout(context),
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

          // ── Content + glass topbar ─────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildGlassTopbar(
                    context, isDark, tokens, scheme, loc),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmStaff,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/staff');
  }

  Widget _buildGlassTopbar(
    BuildContext context,
    bool isDark,
    AppThemeTokens? tokens,
    ColorScheme scheme,
    String loc,
  ) {
    final topbarBg = tokens?.topbarBg ??
        (isDark ? const Color(0xFF0A1628) : Colors.white);
    final borderColor = tokens?.divider ??
        (isDark
            ? const Color(0x2EFFFFFF)
            : const Color(0xFFCDD9F0));
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
                : AppColors.lightSurface,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? borderColor
                    : AppColors.lightBorder,
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
                      _isSidebarCollapsed
                          ? Icons.menu_open
                          : Icons.menu,
                      key: ValueKey(_isSidebarCollapsed),
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  tooltip: _isSidebarCollapsed
                      ? AppStrings.expandSidebar
                      : AppStrings.collapseSidebar,
                  onPressed: () => setState(
                    () =>
                        _isSidebarCollapsed = !_isSidebarCollapsed,
                  ),
                ),
              ),
              const Spacer(),
              IconTheme(
                data: IconThemeData(color: iconColor, size: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NotificationsBellButton(),
                    AppSpacing.hGapXs,
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

// ── Sidebar Nav List ─────────────────────────────────────────────────────────

class _StaffSidebarNavList extends ConsumerWidget {
  const _StaffSidebarNavList({
    required this.loc,
    required this.isCollapsed,
  });
  final String loc;
  final bool isCollapsed;

  bool _isActive(String currentLoc, String route) {
    if (route == '/staff/dashboard' || route == '/staff/profile') {
      return currentLoc == route;
    }
    return currentLoc.startsWith(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingProfileRequestsCountProvider);
    final badgeCount = pendingCount.valueOrNull ?? 0;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      children: [
        for (final item in _navItems)
          item.route == '/staff/profile-requests'
              ? _BadgedNavItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  isActive: _isActive(loc, item.route),
                  onTap: () => context.go(item.route),
                  isCollapsed: isCollapsed,
                  badgeCount: badgeCount,
                )
              : _NavItem(
                  icon: item.icon,
                  activeIcon: item.activeIcon,
                  label: item.label,
                  isActive: _isActive(loc, item.route),
                  onTap: () => context.go(item.route),
                  isCollapsed: isCollapsed,
                ),
        _NavGroup(
          label: AppStrings.account,
          isCollapsed: isCollapsed,
          children: [
            for (final item in _accountItems)
              _NavItem(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: _isActive(loc, item.route),
                onTap: () => context.go(item.route),
                isCollapsed: isCollapsed,
              ),
          ],
        ),
      ],
    );
  }
}

// ── Nav Group (collapsible section header) ───────────────────────────────────

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
    final divColor = t?.divider.withValues(alpha: 0.3) ??
        Colors.white.withValues(alpha: 0.15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child:
          Divider(indent: 12, endIndent: 12, height: 1, color: divColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final labelColor = t?.navItemText.withValues(alpha: 0.6) ??
        Colors.white.withValues(alpha: 0.45);
    final chevronColor = t?.navItemIcon.withValues(alpha: 0.6) ??
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

// ── Nav Item (glass sidebar) ─────────────────────────────────────────────────

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
    final inactiveIconColor =
        t?.navItemIcon ?? const Color(0xFFAEC6E8);
    final inactiveTextColor =
        t?.navItemText ?? const Color(0xFFAEC6E8);
    final activeBg =
        t?.navItemActiveBg ?? const Color(0x2E60A5FA);
    final hoverBg = t?.navItemActiveBg.withValues(alpha: 0.5) ??
        const Color(0x1460A5FA);
    final activeAccent =
        t?.navItemActiveIcon ?? const Color(0xFF60A5FA);
    final borderHint = t?.divider.withValues(alpha: 0.3) ??
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
                      color:
                          isActive ? activeTextColor : inactiveIconColor,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(
                      isActive ? activeIcon : icon,
                      size: 18,
                      color:
                          isActive ? activeTextColor : inactiveIconColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? activeTextColor
                              : inactiveTextColor,
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

// ── Badged Nav Item ──────────────────────────────────────────────────────────

class _BadgedNavItem extends StatelessWidget {
  const _BadgedNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.badgeCount,
    this.isCollapsed = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final activeTextColor = t?.navItemActiveText ?? Colors.white;
    final inactiveIconColor =
        t?.navItemIcon ?? const Color(0xFFAEC6E8);
    final inactiveTextColor =
        t?.navItemText ?? const Color(0xFFAEC6E8);
    final activeBg =
        t?.navItemActiveBg ?? const Color(0x2E60A5FA);
    final hoverBg = t?.navItemActiveBg.withValues(alpha: 0.5) ??
        const Color(0x1460A5FA);
    final activeAccent =
        t?.navItemActiveIcon ?? const Color(0xFF60A5FA);
    final borderHint = t?.divider.withValues(alpha: 0.3) ??
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive ? activeIcon : icon,
                          size: 21,
                          color: isActive
                              ? activeTextColor
                              : inactiveIconColor,
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            right: -AppSpacing.xs,
                            top: -AppSpacing.xs,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(AppSpacing.xs),
                              decoration: const BoxDecoration(
                                color: AppColors.error500,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: AppIconSize.sm,
                                minHeight: AppIconSize.sm,
                              ),
                              child: Text(
                                badgeCount > 99
                                    ? '99+'
                                    : '$badgeCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeAccent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isActive ? activeIcon : icon,
                          size: 18,
                          color: isActive
                              ? activeTextColor
                              : inactiveIconColor,
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            right: -AppSpacing.xs,
                            top: -AppSpacing.xs,
                            child: Container(
                              padding:
                                  const EdgeInsets.all(AppSpacing.xs),
                              decoration: const BoxDecoration(
                                color: AppColors.error500,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: AppIconSize.sm,
                                minHeight: AppIconSize.sm,
                              ),
                              child: Text(
                                badgeCount > 99
                                    ? '99+'
                                    : '$badgeCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? activeTextColor
                              : inactiveTextColor,
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

// ── Profile Avatar Button (topbar) ───────────────────────────────────────────

class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton({this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authGuardProvider);
    final initials = _getInitials(authState.userEmail ?? '');

    return Tooltip(
      message: AppStrings.profile,
      child: InkWell(
        onTap: () => context.go('/staff/profile'),
        borderRadius: AppRadius.brXl2,
        child: Padding(
          padding: AppSpacing.paddingXs,
          child: Builder(builder: (ctx) {
            final t = Theme.of(ctx).extension<AppThemeTokens>();
            return CircleAvatar(
              radius: size / 2,
              backgroundColor: t?.primary ?? _badgeBgColor,
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
    if (email.isEmpty) return 'ST';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2
        ? email.substring(0, 2).toUpperCase()
        : 'ST';
  }
}

// ── Mobile Layout ────────────────────────────────────────────────────────────

class _StaffMobileLayout extends ConsumerStatefulWidget {
  const _StaffMobileLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_StaffMobileLayout> createState() =>
      _StaffMobileLayoutState();
}

class _StaffMobileLayoutState extends ConsumerState<_StaffMobileLayout> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.contains('/staff/fees')) {
      _currentIndex = 1;
    } else if (loc.contains('/staff/students')) {
      _currentIndex = 2;
    } else if (loc.contains('/staff/notices') ||
        loc.contains('/staff/notifications') ||
        loc.contains('/staff/profile') ||
        loc.contains('/staff/change-password')) {
      _currentIndex = 3;
    } else {
      _currentIndex = 0;
    }
  }

  String _initials(String email) {
    if (email.isEmpty) return 'ST';
    final parts = email.split('@').first.split(RegExp(r'[.\s_]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.length >= 2
        ? email.substring(0, 2).toUpperCase()
        : 'ST';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authGuardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

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
                    size: compact ? 24 : 28, showText: true),
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
                      AppStrings.staffBadge,
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
            onPressed: () => context.go('/staff/profile'),
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
            tooltip: AppStrings.profile,
          ),
        ],
      ),
      drawer: _StaffDrawer(
        isDark: isDark,
        scheme: scheme,
        authEmail: authState.userEmail ?? AppStrings.staffBadge,
        getInitials: _initials,
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/staff/dashboard');
            case 1:
              context.go('/staff/fees');
            case 2:
              context.go('/staff/students');
            case 3:
              _scaffoldKey.currentState?.openDrawer();
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accentColor,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              label: AppStrings.dashboard),
          BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              label: AppStrings.fees),
          BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              label: AppStrings.students),
          BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: AppStrings.more),
        ],
      ),
    );
  }
}

// ── Glass Drawer ─────────────────────────────────────────────────────────────

class _StaffDrawer extends ConsumerWidget {
  const _StaffDrawer({
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

    bool isActive(String route) {
      if (route == '/staff/dashboard' || route == '/staff/profile') {
        return loc == route;
      }
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
                // Header
                _DrawerHeader(
                  isDark: isDark,
                  scheme: scheme,
                  email: authEmail,
                  initials: getInitials(authEmail),
                  badgeLabel: AppStrings.staffBadge,
                  badgeColor: _badgeBgColor,
                ),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      _drawerSectionLabel(
                          AppStrings.main, isDark, scheme),
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
                      _drawerSectionLabel(
                          AppStrings.account, isDark, scheme),
                      for (final item in _accountItems)
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

                // Logout
                Divider(height: 1, color: divColor),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: _LogoutTile(
                    isDark: isDark,
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

  Widget _drawerSectionLabel(
      String label, bool isDark, ColorScheme scheme) {
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

  Future<void> _confirmAndLogout(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: AppStrings.signOutQuestion,
      message: AppStrings.signOutConfirmStaff,
      confirmLabel: AppStrings.signOut,
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).pop(); // close drawer
    await ref.read(authGuardProvider.notifier).clearSession();
    if (context.mounted) context.go('/login/staff');
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
              backgroundColor: badgeColor,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: AppRadius.brXs,
            ),
            child: Text(
              badgeLabel,
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

// ── Logout tile for drawer ───────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    final textColor = t?.navItemText ??
        (isDark ? Colors.white : const Color(0xFF0F2044));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.error500),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.signOut,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
