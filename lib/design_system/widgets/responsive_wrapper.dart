// =============================================================================
// FILE: lib/shared/widgets/responsive_wrapper.dart
// PURPOSE: Adaptive layout wrapper for Web, Tablet, and Mobile
// =============================================================================

import 'package:flutter/material.dart';
import '../tokens/theme.dart';

class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.padding,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final EdgeInsetsGeometry? padding;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet &&
      MediaQuery.sizeOf(context).width < AppBreakpoints.laptop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.laptop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        Widget content;
        if (width >= AppBreakpoints.laptop) {
          content = desktop;
        } else if (width >= AppBreakpoints.tablet) {
          content = tablet ?? desktop;
        } else {
          content = mobile;
        }

        if (padding != null) {
          return Padding(padding: padding!, child: content);
        }
        return content;
      },
    );
  }
}

/// Helper for fixed-width content on large screens (e.g. login form)
class MaxWidthContainer extends StatelessWidget {
  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.formMaxWidth,
    this.center = true,
  });

  final Widget child;
  final double maxWidth;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final container = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    
    if (center) return Center(child: container);
    return container;
  }
}
