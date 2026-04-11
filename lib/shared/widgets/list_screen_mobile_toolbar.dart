// =============================================================================
// FILE: lib/shared/widgets/list_screen_mobile_toolbar.dart
// PURPOSE: Shared mobile search + filter strip (matches Super Admin Schools UX).
//          Use on narrow viewports (< 600px) for consistent list/table screens.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../design_system/design_system.dart';

/// Page background tint behind search + filters (light blue-grey strip).
class ListScreenMobileFilterStrip extends StatelessWidget {
  const ListScreenMobileFilterStrip({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Pill outline for [SearchableDropdownFormField] and similar on mobile filter rows.
InputDecoration listScreenMobileFilterFieldDecoration(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final border = OutlineInputBorder(
    borderRadius: AppRadius.brFull,
    borderSide: BorderSide(color: cs.outlineVariant),
  );
  return InputDecoration(
    filled: true,
    fillColor: cs.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.brFull,
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
  );
}

/// Full-width pill search field with clear affordance when text is non-empty.
class ListScreenMobilePillSearchField extends StatefulWidget {
  const ListScreenMobilePillSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onClear;

  @override
  State<ListScreenMobilePillSearchField> createState() =>
      _ListScreenMobilePillSearchFieldState();
}

class _ListScreenMobilePillSearchFieldState extends State<ListScreenMobilePillSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(ListScreenMobilePillSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final searchBorder = OutlineInputBorder(
      borderRadius: AppRadius.brFull,
      borderSide: BorderSide(color: cs.outlineVariant),
    );
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: cs.surface,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, size: 20, color: cs.outline),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: widget.onClear,
              )
            : null,
        border: searchBorder,
        enabledBorder: searchBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brFull,
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      ),
      onChanged: (v) {
        widget.onChanged?.call(v);
      },
      onSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}

/// Distributes [children] evenly with 8px gaps (each child is wrapped in [Expanded]).
class ListScreenMobileFilterRow extends StatelessWidget {
  const ListScreenMobileFilterRow({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

/// Title row: bold heading + export icon + optional primary action (e.g. Add).
class ListScreenMobileHeader extends StatelessWidget {
  const ListScreenMobileHeader({
    super.key,
    required this.title,
    this.onExport,
    this.exportEnabled = true,
    this.primaryLabel,
    this.onPrimary,
    this.primaryIcon = Icons.add,
  });

  final String title;
  final VoidCallback? onExport;
  final bool exportEnabled;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final IconData primaryIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (onExport != null)
            IconButton(
              tooltip: AppStrings.export,
              onPressed: exportEnabled ? onExport : null,
              icon: const Icon(Icons.download_outlined, size: 22),
            ),
          if (onPrimary != null && primaryLabel != null)
            FilledButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon, size: 20),
              label: Text(primaryLabel!),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
        ],
      ),
    );
  }
}

/// Third-column control: tune icon, optional active dot, label, chevron (opens more filters).
class ListScreenMobileMoreFiltersButton extends StatelessWidget {
  const ListScreenMobileMoreFiltersButton({
    super.key,
    required this.onPressed,
    this.showActiveDot = false,
    this.label = AppStrings.filters,
  });

  final VoidCallback onPressed;
  final bool showActiveDot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        backgroundColor: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 16, color: cs.onSurfaceVariant),
          if (showActiveDot) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
