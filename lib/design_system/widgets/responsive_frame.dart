// =============================================================================
// FILE: lib/design_system/widgets/responsive_frame.dart
// PURPOSE: Atomic layout wrapper that ensures safety and responsive awareness.
// =============================================================================

import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop, widescreen }

/// A safe, constraint-conscious wrapper for all responsive layouts.
/// It prevents "Cannot hit test" and "Unbounded height" errors by enforcing 
/// finite constraints via LayoutBuilder.
class AppResponsiveFrame extends StatelessWidget {
  const AppResponsiveFrame({
    super.key,
    required this.builder,
    this.useSafeArea = true,
  });

  /// The builder provides constraints and current device type.
  final Widget Function(BuildContext context, BoxConstraints constraints, DeviceType deviceType) builder;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // SAFETY: Fallback to screen size if constraints are unhelpfully small, 
        // zero, or infinite to avoid hit-test errors and Box.dart assertions.
        final sz = MediaQuery.of(context).size;
        final maxWidth = (constraints.maxWidth > 0 && constraints.maxWidth.isFinite) 
            ? constraints.maxWidth 
            : sz.width;
        final maxHeight = (constraints.maxHeight > 0 && constraints.maxHeight.isFinite) 
            ? constraints.maxHeight 
            : sz.height;

        final width = maxWidth;
        DeviceType deviceType;

        if (width >= 1440) {
          deviceType = DeviceType.widescreen;
        } else if (width >= 1024) {
          deviceType = DeviceType.desktop;
        } else if (width >= 640) {
          deviceType = DeviceType.tablet;
        } else {
          deviceType = DeviceType.mobile;
        }

        Widget content = builder(
          context, 
          BoxConstraints(
            maxWidth: maxWidth, 
            maxHeight: maxHeight,
            minWidth: 0,
            minHeight: 0,
          ), 
          deviceType
        );

        if (useSafeArea) {
          content = SafeArea(child: content);
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: (maxWidth > 0) ? maxWidth : 0,
            minHeight: (maxHeight > 0) ? maxHeight : 0,
          ),
          child: content,
        );
      },
    );
  }
}

/// Helper to get device type outside of the builder context if needed.
extension DeviceContext on BuildContext {
  DeviceType get deviceType {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1440) return DeviceType.widescreen;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 640)  return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop || deviceType == DeviceType.widescreen;
}
