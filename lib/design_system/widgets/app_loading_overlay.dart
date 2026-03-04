// =============================================================================
// FILE: lib/shared/widgets/app_loading_overlay.dart
// PURPOSE: Full-screen or container-level loading blur/overlay
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../tokens/theme.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.label,
    this.blur = 2.0,
    this.opacity = 0.5,
  });

  final Widget child;
  final bool isLoading;
  final String? label;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  color: scheme.surface.withAlpha((opacity * 255).round()),
                  child: Center(
                    child: AppLoader(
                      label: label ?? 'Processing...',
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
