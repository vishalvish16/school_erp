// =============================================================================
// FILE: lib/shared/layouts/admin_layout.dart
// PURPOSE: Enterprise SaaS Dashboard Layout (Root Shell)
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveFrame(
      useSafeArea: false,
      builder: (context, constraints, deviceType) {
        final isMobile = deviceType == DeviceType.mobile;
        final isTablet = deviceType == DeviceType.tablet;
        final isLarge = deviceType == DeviceType.desktop || deviceType == DeviceType.widescreen;

        return Scaffold(
          key: _scaffoldKey,
          
          // ── Mobile Drawer ──────────────────────────────────────────────────
          drawer: (isMobile || isTablet)
              ? Drawer(
                  width: 260,
                  child: AdminSidebar(
                    isCollapsed: false,
                    onToggle: () => _scaffoldKey.currentState?.closeDrawer(),
                  ),
                )
              : null,

          body: Row(
            children: [
              // ── Desktop/Tablet Sidebar ─────────────────────────────────────
              if (isLarge)
                AdminSidebar(
                  isCollapsed: _isSidebarCollapsed,
                  onToggle: _toggleSidebar,
                ),

              // ── Main Content Area ──────────────────────────────────────────
              Expanded(
                child: SafeArea(
                  bottom: false, // Let lists or child content bleed to the bottom edge if designed
                  child: Column(
                    children: [
                      // Persistent Topbar
                      AdminTopbar(
                        showMenuButton: !isLarge,
                        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),

                      // Dynamic Child Content
                      Expanded(
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                          child: SelectionArea(
                            child: widget.child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
