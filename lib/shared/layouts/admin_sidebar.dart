// =============================================================================
// FILE: lib/shared/layouts/admin_sidebar.dart
// PURPOSE: Enterprise SaaS Sidebar with Collapsible logic & Route Awareness
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import '../models/sidebar_menu_model.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Branding Section ───────────────────────────────────────────────
            Container(
              height: 72,
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
              alignment: Alignment.centerLeft,
              child: AppLogoWidget(
                size: 32,
                showText: !isCollapsed,
              ),
            ),

            const Divider(height: 1),

            // ── Menu Section ───────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  for (final section in SuperAdminNavigation.sections) ...[
                    if (SuperAdminNavigation.sections.indexOf(section) > 0)
                      const SizedBox(height: 24),
                    _SidebarGroup(title: section.title, isCollapsed: isCollapsed),
                    for (final item in section.items)
                      _SidebarItem(
                        icon: item.icon,
                        activeIcon: item.activeIcon ?? item.icon,
                        label: item.title,
                        route: item.route,
                        isCollapsed: isCollapsed,
                        isActive: item.route == '/dashboard' 
                            ? location == '/dashboard' 
                            : location.startsWith(item.route),
                      ),
                  ],
                ],
              ),
            ),

            // ── Collapse Toggle (Floating at bottom for better Fitts Law) ───────
            const Divider(height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onToggle,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: isCollapsed 
                        ? MainAxisAlignment.center 
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCollapsed) 
                        Text(
                          'Collapse Sidebar', 
                          style: AppTextStyles.caption(color: scheme.onSurfaceVariant)
                        ),
                      Icon(
                        isCollapsed 
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
    );
  }
}

class _SidebarGroup extends StatelessWidget {
  const _SidebarGroup({required this.title, required this.isCollapsed});
  final String title;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) return const Divider(height: 32, indent: 8, endIndent: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.overline(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.isCollapsed,
    required this.isActive,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final bool isCollapsed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? scheme.primaryContainer.withAlpha(80) : Colors.transparent,
        borderRadius: AppRadius.brMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: AppRadius.brMd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                ),
                if (!isCollapsed) ...[
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.body(
                        color: isActive ? scheme.primary : scheme.onSurface,
                      ).copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(2),
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
      return Tooltip(
        message: label,
        preferBelow: false,
        child: content,
      );
    }
    return content;
  }
}
