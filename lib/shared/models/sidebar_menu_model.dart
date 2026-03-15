// =============================================================================
// FILE: lib/shared/models/sidebar_menu_model.dart
// PURPOSE: Unified model for sidebar navigation entries with support for nesting.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

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
      title: AppStrings.platform,
      items: [
        SidebarMenuModel(
          title: AppStrings.dashboard,
          route: '/dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
        ),
        SidebarMenuModel(
          title: AppStrings.schools,
          route: '/schools',
          icon: Icons.school_outlined,
          activeIcon: Icons.school,
        ),
        SidebarMenuModel(
          title: AppStrings.branches,
          route: '/branches',
          icon: Icons.account_tree_outlined,
          activeIcon: Icons.account_tree,
        ),
        SidebarMenuModel(
          title: AppStrings.plans,
          route: '/plans',
          icon: Icons.layers_outlined,
          activeIcon: Icons.layers,
        ),
      ],
    ),
    SidebarSection(
      title: AppStrings.administration,
      items: [
        SidebarMenuModel(
          title: AppStrings.users,
          route: '/users',
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
        ),
        SidebarMenuModel(
          title: AppStrings.roles,
          route: '/roles',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
        ),
        SidebarMenuModel(
          title: AppStrings.modules,
          route: '/modules',
          icon: Icons.extension_outlined,
          activeIcon: Icons.extension,
        ),
      ],
    ),
    SidebarSection(
      title: AppStrings.financials,
      items: [
        SidebarMenuModel(
          title: AppStrings.subscriptions,
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
      title: AppStrings.system,
      items: [
        SidebarMenuModel(
          title: AppStrings.auditLogs,
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
          title: AppStrings.settings,
          route: '/settings',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
        ),
      ],
    ),
  ];
}
