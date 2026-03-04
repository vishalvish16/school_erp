// =============================================================================
// FILE: lib/shared/models/sidebar_menu_model.dart
// PURPOSE: Unified model for sidebar navigation entries with support for nesting.
// =============================================================================

import 'package:flutter/material.dart';

class SidebarMenuModel {
  const SidebarMenuModel({
    required this.title,
    required this.route,
    required this.icon,
    this.activeIcon,
    this.children,
    this.isPlatformOnly = false,
    this.isActive = true,
  });

  final String title;
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final List<SidebarMenuModel>? children;
  final bool isPlatformOnly;
  final bool isActive;
}

class SidebarSection {
  const SidebarSection({
    required this.title,
    required this.items,
    this.isPlatformOnly = false,
  });

  final String title;
  final List<SidebarMenuModel> items;
  final bool isPlatformOnly;
}

/// Centralized navigation definition for the platform.
abstract final class SuperAdminNavigation {
  static const List<SidebarSection> sections = [
    SidebarSection(
      title: 'Platform',
      items: [
        SidebarMenuModel(
          title: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
        ),
        SidebarMenuModel(
          title: 'Schools',
          route: '/schools',
          icon: Icons.school_outlined,
          activeIcon: Icons.school,
        ),
        SidebarMenuModel(
          title: 'Branches',
          route: '/branches',
          icon: Icons.account_tree_outlined,
          activeIcon: Icons.account_tree,
        ),
        SidebarMenuModel(
          title: 'Plans',
          route: '/plans',
          icon: Icons.layers_outlined,
          activeIcon: Icons.layers,
        ),
      ],
    ),
    SidebarSection(
      title: 'Administration',
      items: [
        SidebarMenuModel(
          title: 'Users',
          route: '/users',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
        SidebarMenuModel(
          title: 'Roles',
          route: '/roles',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
        ),
        SidebarMenuModel(
          title: 'Modules',
          route: '/modules',
          icon: Icons.extension_outlined,
          activeIcon: Icons.extension,
        ),
      ],
    ),
    SidebarSection(
      title: 'Financials',
      items: [
        SidebarMenuModel(
          title: 'Subscriptions',
          route: '/subscriptions',
          icon: Icons.subscriptions_outlined,
          activeIcon: Icons.subscriptions,
        ),
        SidebarMenuModel(
          title: 'Revenue',
          route: '/revenue',
          icon: Icons.payments_outlined,
          activeIcon: Icons.payments,
        ),
      ],
    ),
    SidebarSection(
      title: 'System',
      items: [
        SidebarMenuModel(
          title: 'Audit Logs',
          route: '/audit-logs',
          icon: Icons.history_edu_outlined,
          activeIcon: Icons.history_edu,
        ),
        SidebarMenuModel(
          title: 'System Health',
          route: '/system-health',
          icon: Icons.health_and_safety_outlined,
          activeIcon: Icons.health_and_safety,
        ),
        SidebarMenuModel(
          title: 'Settings',
          route: '/settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
        ),
      ],
    ),
  ];
}
