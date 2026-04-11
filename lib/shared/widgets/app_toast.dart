// =============================================================================
// FILE: lib/shared/widgets/app_toast.dart
// PURPOSE: Centered, icon-styled toast notifications for success/error/warning/info
// Usage:
//   AppToast.showSuccess(context, 'Theme saved!');
//   AppToast.showError(context, 'Something went wrong.');
//   AppToast.showWarning(context, 'Check your input.');
//   AppToast.showInfo(context, 'Processing...');
// =============================================================================

import 'package:flutter/material.dart';

enum _ToastType { success, error, warning, info }

class AppToast {
  static void showSuccess(BuildContext context, String message) =>
      _show(context, message, _ToastType.success);

  static void showError(BuildContext context, String message) =>
      _show(context, message, _ToastType.error);

  static void showWarning(BuildContext context, String message) =>
      _show(context, message, _ToastType.warning);

  static void showInfo(BuildContext context, String message) =>
      _show(context, message, _ToastType.info);

  static void _show(BuildContext context, String message, _ToastType type) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ToastEntry(
        message: message,
        type: type,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (entry.mounted) entry.remove();
    });
  }
}

// ─── Animated entry widget ────────────────────────────────────────────────────

class _ToastEntry extends StatefulWidget {
  const _ToastEntry({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final _ToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastEntry> createState() => _ToastEntryState();
}

class _ToastEntryState extends State<_ToastEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 24,
      left: 0,
      right: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: _ToastCard(
                message: widget.message,
                type: widget.type,
                onClose: widget.onDismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Toast card ───────────────────────────────────────────────────────────────

class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.message,
    required this.type,
    required this.onClose,
  });

  final String message;
  final _ToastType type;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (bg, accentColor, iconData, label) = switch (type) {
      _ToastType.success => (
          const Color(0xFF052E1A),
          const Color(0xFF34D399),
          Icons.check_circle_rounded,
          'Success',
        ),
      _ToastType.error => (
          const Color(0xFF4C0519),
          const Color(0xFFF87171),
          Icons.error_rounded,
          'Error',
        ),
      _ToastType.warning => (
          const Color(0xFF431407),
          const Color(0xFFFBBF24),
          Icons.warning_rounded,
          'Warning',
        ),
      _ToastType.info => (
          const Color(0xFF082030),
          const Color(0xFF38BDF8),
          Icons.info_rounded,
          'Info',
        ),
    };

    const textColor = Color(0xFFF0F9FF);

    return Container(
      constraints: const BoxConstraints(maxWidth: 460, minWidth: 240),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: accentColor.withValues(alpha: 0.55), width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(width: 5, color: accentColor),

              // Icon + content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                child: Icon(iconData, color: accentColor, size: 24),
              ),

              // Text block
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 8, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 10, 8),
                child: GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    color: textColor.withValues(alpha: 0.45),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
