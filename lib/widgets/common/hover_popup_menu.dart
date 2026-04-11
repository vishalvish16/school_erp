// =============================================================================
// FILE: lib/widgets/common/hover_popup_menu.dart
// PURPOSE: A wrapper for MenuAnchor that opens on hover (Web) and 
//          falls back to PopupMenuButton (Mobile).
// =============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';

class HoverPopupMenu<T> extends StatefulWidget {
  const HoverPopupMenu({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.icon,
    this.padding = EdgeInsets.zero,
  });

  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final void Function(T)? onSelected;
  final Widget? icon;
  final EdgeInsetsGeometry padding;

  @override
  State<HoverPopupMenu<T>> createState() => _HoverPopupMenuState<T>();
}

class _HoverPopupMenuState<T> extends State<HoverPopupMenu<T>> {
  final MenuController _controller = MenuController();
  Timer? _closeTimer;

  void _open() {
    _closeTimer?.cancel();
    if (!_controller.isOpen) {
      _controller.open();
    }
  }

  void _close() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 100), () {
      if (_controller.isOpen && mounted) {
        _controller.close();
      }
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // On mobile PopupMenuButton with explicit surface background so menu
    // items are always readable on the glass campus background.
    if (!kIsWeb) {
      return PopupMenuButton<T>(
        itemBuilder: widget.itemBuilder,
        onSelected: widget.onSelected,
        icon: widget.icon,
        padding: widget.padding,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final items = widget.itemBuilder(context);

    return MouseRegion(
      onEnter: (_) => _open(),
      onExit: (_) => _close(),
      child: MenuAnchor(
        controller: _controller,
        style: MenuStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          // Match card background exactly — suppress M3 elevation tint.
          backgroundColor: WidgetStateProperty.all(scheme.surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(8),
          shadowColor: WidgetStateProperty.all(
              scheme.shadow.withValues(alpha: 0.25)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        menuChildren: items.map((entry) {
          if (entry is PopupMenuItem<T>) {
            return MouseRegion(
              onEnter: (_) => _open(),
              onExit: (_) => _close(),
              child: MenuItemButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return scheme.primary.withValues(alpha: 0.08);
                    }
                    return Colors.transparent;
                  }),
                  minimumSize: WidgetStateProperty.all(
                      const Size(180, 44)),
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                ),
                onPressed: entry.enabled
                    ? () {
                        if (widget.onSelected != null) {
                          widget.onSelected!(entry.value as T);
                        }
                        _controller.close();
                      }
                    : null,
                child: entry.child ?? Text(entry.value.toString()),
              ),
            );
          }
          if (entry is PopupMenuDivider) {
            return Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5));
          }
          return const SizedBox.shrink();
        }).toList(),
        builder: (context, controller, child) {
          return IconButton(
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            icon: widget.icon ?? const Icon(Icons.more_vert, size: 20),
            padding: widget.padding,
          );
        },
      ),
    );
  }
}
