// =============================================================================
// FILE: lib/design_system/widgets/app_buttons.dart
// PURPOSE: Reusable action buttons with loading states and design system integration
// =============================================================================

import 'package:flutter/material.dart';
import '../tokens/theme.dart';

/// Base button class to avoid duplication
class _AppButtonBase extends StatelessWidget {
  const _AppButtonBase({
    required this.child,
    required this.onPressed,
    this.style,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.md,
    this.icon,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isLoading;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? AppButtonStyles.primary(size: size);

    Widget content;

    if (isLoading) {
      content = Center(child: AppLoader.inline(color: Colors.white));
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          AppSpacing.hGapSm,
          Flexible(
            child: DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              child: child,
            ),
          ),
        ],
      );
    } else {
      content = DefaultTextStyle.merge(
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        child: child,
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        width: width,
        height: height ?? size.height,
        child: ElevatedButton(
          style: effectiveStyle,
          onPressed: isLoading ? null : onPressed,
          child: content,
        ),
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.md,
    this.icon,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      size: size,
      icon: icon,
      style: AppButtonStyles.primary(size: size),
      child: child,
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.md,
    this.icon,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      size: size,
      icon: icon,
      style: AppButtonStyles.secondary(size: size),
      child: child,
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.md,
    this.icon,
    this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final AppButtonSize size;
  final Widget? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.primary;

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      child: SizedBox(
        width: width,
        height: height ?? size.height,
        child: OutlinedButton(
          style: AppButtonStyles.outline(size: size, color: effectiveColor),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? AppLoader.inline(color: effectiveColor)
              : icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon!,
                    AppSpacing.hGapSm,
                    Flexible(
                      child: DefaultTextStyle.merge(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        child: child,
                      ),
                    ),
                  ],
                )
              : DefaultTextStyle.merge(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  child: child,
                ),
        ),
      ),
    );
  }
}
