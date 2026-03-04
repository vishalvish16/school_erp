// =============================================================================
// FILE: lib/shared/widgets/theme_toggle_button.dart
// PURPOSE: Dedicated theme toggle button with animations
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../tokens/theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // We expect a ThemeNotifier to be available in the context via Provider
    final notifier = context.watch<ThemeNotifier>();
    final isDark   = notifier.isDark;

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            key: ValueKey(isDark),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onPressed: notifier.toggle,
      ),
    );
  }
}
