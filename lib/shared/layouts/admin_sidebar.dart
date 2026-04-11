// =============================================================================
// FILE: lib/shared/layouts/admin_sidebar.dart
// PURPOSE: Enterprise SaaS Sidebar with Collapsible logic & Route Awareness
// =============================================================================

import 'dart:ui' as ui;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: isCollapsed ? 80 : 260,
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
                color: isDark
                    ? scheme.surface.withValues(alpha: 0.88)
                    : AppColors.lightSurface,
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? scheme.outlineVariant
                        : AppColors.lightBorder,
                    width: 1,
                  ),
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
                padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: isCollapsed ? 8 : 12,
                ),
                children: [
                  for (final section in SuperAdminNavigation.sections) ...[
                    if (SuperAdminNavigation.sections.indexOf(section) > 0)
                      AppSpacing.vGapXl,
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
                  padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 20),
                  child: Row(
                    mainAxisAlignment: isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isCollapsed)
                        Expanded(
                          child: Text(
                            'Collapse Sidebar',
                            style: AppTextStyles.caption(color: scheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
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
      ),        // closes SafeArea
            ),  // closes Container (glass decoration)
          ),    // closes BackdropFilter
        ),      // closes ClipRect
    ),          // closes AnimatedContainer
    );          // closes RepaintBoundary
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
      duration: const Duration(milliseconds: 120),
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
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12),
            child: isCollapsed
                ? Center(
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 20,
                      color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        isActive ? activeIcon : icon,
                        size: 20,
                        color: isActive ? scheme.primary : scheme.onSurfaceVariant,
                      ),
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
                            borderRadius: AppRadius.brXs,
                          ),
                        ),
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
