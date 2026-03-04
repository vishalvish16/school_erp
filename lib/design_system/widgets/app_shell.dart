// =============================================================================
// FILE: lib/design_system/widgets/app_shell.dart
// PURPOSE: Multi-role SaaS Scaffolding with Sidebar and Top-bar support.
// =============================================================================

import 'package:flutter/material.dart';
import 'responsive_frame.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.sidebar,
    this.topBar,
    this.footer,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? sidebar;
  final Widget? topBar;
  final Widget? footer;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: AppResponsiveFrame(
        useSafeArea: false, // Shell handles its own safe area
        builder: (context, constraints, deviceType) {
          final isLarge = deviceType == DeviceType.desktop || deviceType == DeviceType.widescreen;

          return Row(
            children: [
              // ── Sidebar (Only on Large Screens) ───────────────────────────
              if (isLarge && sidebar != null) ...[
                SizedBox(
                  width: 260, // Fixed SaaS sidebar width
                  child: sidebar!,
                ),
                const VerticalDivider(width: 1),
              ],

              // ── Main Content Area ──────────────────────────────────────────
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    if (topBar != null) ...[
                      topBar!,
                      const Divider(height: 1),
                    ],

                    // Page Body
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: body,
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    if (footer != null) ...[
                      const Divider(height: 1),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Drawer for mobile/tablet
      drawer: (context.isMobile || context.isTablet) && sidebar != null
          ? Drawer(child: sidebar)
          : null,
    );
  }
}

/// A standardized content wrapper for the AppShell to ensure visual consistency.
class AppContentArea extends StatelessWidget {
  const AppContentArea({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(24),
    this.isScrollable = true,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enforce finite height for the scroll view. Fallback to screen height if infinite.
        final viewportHeight = constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : MediaQuery.of(context).size.height;

        Widget body = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        );

        if (isScrollable) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportHeight.isFinite ? viewportHeight : 0,
              ),
              child: body,
            ),
          );
        }

        return body;
      },
    );
  }
}
