// =============================================================================
// FILE: lib/shared/widgets/app_logo.dart
// PURPOSE: Global application logo widget
// =============================================================================

import 'package:flutter/material.dart';
import '../tokens/theme.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key, this.size = 40, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      // ── Collapsed State: Icon Only ─────────────────────────────────────────
      return _buildLogo(context, isOnlyIcon: true);
    }

    // ── Expanded State: Full Logo with Text ──────────────────────────────────
    return _buildLogo(context, isOnlyIcon: false);
  }

  Widget _buildLogo(BuildContext context, {required bool isOnlyIcon}) {
    final logoPath = 'assets/images/logo.png';

    Widget logoImage = Image.asset(
      logoPath,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
    );

    if (isOnlyIcon) {
      // Use ClipRect + Align to show only the left part (the infinity symbol)
      // of the wide logo image when collapsed.
      return Hero(
        tag: 'app_logo',
        child: SizedBox(
          width: size,
          height: size,
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.32, // Adjust to crop precisely to the icon
              child: logoImage,
            ),
          ),
        ),
      );
    }

    return Hero(tag: 'app_logo', child: logoImage);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.brMd,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_graph_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
